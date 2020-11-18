package de.jbservices.autofill_service

import android.annotation.SuppressLint
import android.app.Activity.RESULT_OK
import android.app.assist.AssistStructure
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.service.autofill.Dataset
import android.service.autofill.FillResponse
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import mu.KotlinLogging

private val logger = KotlinLogging.logger {}

data class PwDataset(
        val label: String,
        val username: String,
        val password: String
)

@RequiresApi(Build.VERSION_CODES.O)
class AutofillServicePlugin() : FlutterPlugin, MethodCallHandler,
        PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener, ActivityAware {

    companion object {
        // some creative way so we have some more or less unique result code? 🤷️
        val REQUEST_CODE_SET_AUTOFILL_SERVICE =
                AutofillServicePlugin::class.java.hashCode() and 0xffff

    }

    private var context: Context? = null
    private var channel: MethodChannel? = null
    private var autofillManager: AutofillManager? = null
    private var autofillPreferenceStore: AutofillPreferenceStore? = null
    private var requestSetAutofillServiceResult: Result? = null
    private var lastIntent: Intent? = null

    private var activityBinding: ActivityPluginBinding? = null
    private val activity get() = activityBinding?.activity

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.context = binding.applicationContext
        try {
            this.autofillManager = binding.applicationContext.getSystemService(AutofillManager::class.java) ?: null
            this.autofillPreferenceStore = AutofillPreferenceStore.getInstance(binding.applicationContext)
        } catch (e: Throwable) {
        }
        logger.debug { "onAttachedToEngine" }
        var channel = MethodChannel(binding.binaryMessenger, "de.jbservices/autofill_service")
        if (this.autofillManager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            channel.setMethodCallHandler(this)
        } else {
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasAutofillServicesSupport" ->
                        result.success(false)
                    "hasEnabledAutofillServices" ->
                        result.success(null)
                    else -> result.notImplemented()
                }
            }
        }
        this.channel = channel
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        logger.debug { "onDetachedFromEngine" }
        channel?.setMethodCallHandler(null)
        channel = null
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        logger.debug { "got autofillPreferences: ${autofillPreferenceStore?.autofillPreferences}" }
        when (call.method) {
            "hasAutofillServicesSupport" ->
                result.success(true)
            "hasEnabledAutofillServices" ->
                result.success(autofillManager?.hasEnabledAutofillServices())
            "disableAutofillServices" -> {
                autofillManager?.disableAutofillServices()
                result.success(null)
            }
            "requestSetAutofillService" -> {
                val intent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE)
                intent.data = Uri.parse("package:de.jbservices.nc_passwords_app")
                logger.debug { "enableService(): intent=$intent" }
                requestSetAutofillServiceResult = result
                requireNotNull(activity, { "No Activity available." })
                        .startActivityForResult(intent,
                                REQUEST_CODE_SET_AUTOFILL_SERVICE
                        )
                // result will be delivered in onActivityResult!
            }
            // method available while we are handling an autofill request.
            "getAutofillMetadata" -> {
                val metadata = activity?.intent?.getStringExtra(
                        AutofillMetadata.EXTRA_NAME
                )?.let(AutofillMetadata.Companion::fromJsonString)
                logger.debug { "Got metadata: $metadata" }
                result.success(metadata?.toJson())
            }
            "resultWithDataset" -> {
                resultWithDataset(call, result)
            }
            "getPreferences" -> {
                result.success(
                        autofillPreferenceStore?.autofillPreferences?.toJsonValue()
                )
            }
            "setPreferences" -> {
                val prefs = call.argument<Map<String, Any>>("preferences")?.let { data ->
                    AutofillPreferences.fromJsonValue(data)
                } ?: throw IllegalArgumentException("Invalid preferences object.")
                autofillPreferenceStore?.autofillPreferences = prefs
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun resultWithDataset(call: MethodCall, result: Result) {
        val label = call.argument<String>("label") ?: "Autofill"
        val username = call.argument<String>("username") ?: ""
        val password = call.argument<String>("password") ?: ""
        if (password.isBlank()) {
            logger.warn { "No known password." }
        }
        resultWithDatasets(listOf(PwDataset(label, username, password)), result)
    }

    private fun resultWithDatasets(pwDatasets: List<PwDataset>, result: Result) {

        val structureParcel: AssistStructure? =
                lastIntent?.extras?.getParcelable(AutofillManager.EXTRA_ASSIST_STRUCTURE)
                        ?: activity?.intent?.extras?.getParcelable(
                                AutofillManager.EXTRA_ASSIST_STRUCTURE
                        )
        if (structureParcel == null) {
            logger.info { "No structure available. (activity: $activity)" }
            result.success(false)
            return
        }

        val activity = requireNotNull(this.activity)

        val structure = AssistStructureParser(structureParcel)
        val pName = context?.packageName ?: "empty"
        val autofillIds =
                (lastIntent ?: activity.intent)?.extras?.getParcelableArrayList<AutofillId>(
                        "autofillIds"
                )
        logger.debug { "structure: $structure /// autofillIds: $autofillIds" }
        logger.info { "packageName: ${pName}" }

        val remoteViews = {
            RemoteViewsHelper.viewsWithNoAuth(
                    pName, "Fill Me"
            )
        }
//        structure.fieldIds.values.forEach { it.sortByDescending { it.heuristic.weight } }

        val datasetResponse = FillResponse.Builder()
                .setAuthentication(
                        structure.autoFillIds.toTypedArray(),
                        null,
                        null
                )
                .apply {
                    pwDatasets.forEach { pw ->
                        addDataset(Dataset.Builder(remoteViews()).apply {
                            setId("test ${pw.username}")
                            structure.allNodes.forEach { node ->
                                if (node.isFocused && node.autofillId != null) {
                                    logger.debug("Setting focus node. ${node.autofillId}")
                                    setValue(
                                            node.autofillId!!,
                                            AutofillValue.forText(pw.username),
                                            RemoteViews(
                                                    context?.packageName,
                                                    android.R.layout.simple_list_item_1
                                            ).apply {
                                                setTextViewText(android.R.id.text1, pw.label + "(focus)")
                                            })

                                }
                            }
                            val filledAutofillIds = mutableSetOf<AutofillId>()
                            structure.fieldIds.flatMap { entry ->
                                entry.value.map { entry.key to it }
                            }.sortedByDescending { it.second.heuristic.weight }.forEach allIds@{ (type, field) ->
                                val isNewAutofillId = filledAutofillIds.add(field.autofillId)
                                logger.debug("Adding data set at weight ${field.heuristic.weight} for ${type.toString().padStart(10)} for ${field.autofillId} ${"Ignored".takeIf { !isNewAutofillId } ?: ""}")

                                if (!isNewAutofillId) {
                                    return@allIds
                                }

                                val autoFillValue = if (type == AutofillInputType.Password) {
                                    pw.password
                                } else {
                                    pw.username
                                }
                                setValue(
                                        field.autofillId,
                                        AutofillValue.forText(autoFillValue),
                                        RemoteViews(
                                                context?.packageName,
                                                android.R.layout.simple_list_item_1
                                        ).apply {
                                            setTextViewText(android.R.id.text1, pw.label)
                                        })
                            }
                        }.build())
                    }
                }
                .build()
        val replyIntent = Intent().apply {
            // Send the data back to the service.
            putExtra(EXTRA_AUTHENTICATION_RESULT, datasetResponse)
        }

        activity.setResult(RESULT_OK, replyIntent)
        activity.finish()
        result.success(true)
    }

    override fun onNewIntent(intent: Intent?): Boolean {
        lastIntent = intent
        logger.info {
            "We got a new intent. $intent (extras: ${
                intent?.extras?.keySet()?.map {
                    it to intent.extras?.get(
                            it
                    )
                }
            })"
        }
        return false
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        logger.debug(
                "got activity result for $requestCode" +
                        " (our: $REQUEST_CODE_SET_AUTOFILL_SERVICE) result: $resultCode"
        )
        if (requestCode == REQUEST_CODE_SET_AUTOFILL_SERVICE) {
            requestSetAutofillServiceResult?.let { result ->
                requestSetAutofillServiceResult = null
                result.success(resultCode == RESULT_OK)
            } ?: logger.warn { "Got activity result, but did not have a requestResult set." }
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }
}