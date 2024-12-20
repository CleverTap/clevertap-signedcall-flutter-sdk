import Flutter
import SignedCallSDK
import UIKit
import OSLog

public class SwiftClevertapSignedCallFlutterPlugin: NSObject, FlutterPlugin {
    private var callEventTrigger: EventChannelHandler?
    private var channel: FlutterMethodChannel?
    private var logValue: OSLog {
        return SignedCall.isLoggingEnabled ? .default : .disabled
    }
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.callStatus(notification:)), name: SCCallStatusDidUpdate, object: nil)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftClevertapSignedCallFlutterPlugin()
        instance.setupChannel(registrar: registrar)
    }
    
    private func setupChannel(registrar: FlutterPluginRegistrar){
        callEventTrigger = EventChannelHandler(
            id: SCChannel.eventChannel.rawValue,
            messenger: registrar.messenger()
        )
        channel = FlutterMethodChannel(name: SCChannel.methodChannel.rawValue,
                                       binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(self, channel: channel!)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        //logging to debug method
        let methodCall = SCMethodCall(rawValue: call.method)
        
        os_log("Handle flutter method call: %{public}@", log: logValue, type: .default, call.method)

        switch methodCall {
        case .LOGGING:
            let arguments = call.arguments as? [String: Int]
            guard arguments?[SCMethodParams.LOGLEVEL.rawValue] ?? -1 > 0 else {
                SignedCall.isLoggingEnabled = false
                result(nil)
                return
            }
            SignedCall.isLoggingEnabled = true
            result(nil)
            
        case .INIT:
            let arguments = call.arguments as? [String: Any]
            guard let initOptions = arguments?[SCMethodParams.INITPARAM.rawValue] as? [String: Any] else {
                os_log("Handle flutter method INIT, key: initProperties not available", log: logValue, type: .default)
                result(nil)
                return
            }
            initSDK(initOptions, result: result)
            
        case .CALL:
            let arguments = call.arguments as? [String: Any]
            guard let callData = arguments?[SCMethodParams.CALLPARAM.rawValue] as? [String: Any] else {
                os_log("Handle flutter method CALL, key: callProperties not available", log: logValue, type: .default)
                result(nil)
                return
            }
            makeCall(callData, result: result)
            
        case .LOGOUT:
            logout()
            result(nil)
            
        case .HANG_UP_CALL:
            SignedCall.hangup()
            result(nil)
            
        case .DISCONNECTSOCKET:
            SignedCall.disconnectSignallingSocket()
            result(nil)
            
        case .TRACKSDKVERSION:
            if let arguments = call.arguments as? [String: Any],
               let sdkName = arguments["sdkName"] as? String,
               let sdkVersion = arguments["sdkVersion"] as? Int32 {
                SignedCall.cleverTapInstance?.setCustomSdkVersion(sdkName, version: sdkVersion)
            }
        default: result(FlutterMethodNotImplemented)
        }
    }
    
    func logout() {
        SignedCall.logout()
        let _ = callEventTrigger?.onCancel(withArguments: [:])
    }
    
    func initSDK(_ initOptions:[String: Any], result: @escaping FlutterResult) {
        guard let accountId = initOptions[SCMethodParams.ACCOUNTID.rawValue],
              let apiKey = initOptions[SCMethodParams.APIKEY.rawValue],
              let cuid = initOptions[SCMethodParams.CUID.rawValue] else {
            return
        }
        
        var initParams: [String: Any] = [
            "accountID": accountId,
            "apiKey": apiKey,
            "cuid" : cuid
        ]
        if let production = initOptions[SCMethodParams.PRODUCTION.rawValue] {
            initParams["production"] = production
        }
        let branding = initOptions[SCMethodParams.BRANDING.rawValue] as? [String: Any]
        if let bgColor = branding?[SCMethodParams.BGCOLOR.rawValue] as? String,
           let fontColor = branding?[SCMethodParams.FONTCOLOR.rawValue] as? String,
           let logoUrl = branding?[SCMethodParams.LOGOURL.rawValue] as? String,
           let buttonTheme = branding?[SCMethodParams.BUTTONTHEME.rawValue] as? String {
            let theme = buttonTheme == "light"
            SignedCall.overrideDefaultBranding = SCCallScreenBranding(bgColor: bgColor, fontColor: fontColor, logo: logoUrl, buttonTheme: theme ? .light : .dark)
        }
        if let poweredBy = branding?[SCMethodParams.POWEREDBY.rawValue] as? Bool {
            SignedCall.overrideDefaultBranding?.setDisplayPoweredBySignedCall(poweredBy)
        }
        SignedCall.isEnabled = false
        SignedCall.initSDK(withInitOptions: initParams) { [weak self] res in
            DispatchQueue.main.async {
                switch res {
                case .success(_):
                    self?.channel?.invokeMethod(SCMethodParams.ON_SIGNED_CALL_DID_INITIALIZE.rawValue, arguments: nil)
                    result(nil)
                case .failure(let error):
                    let errorObj = [SCMethodParams.errorCode.rawValue:error.errorCode,
                                    SCMethodParams.errorMessage.rawValue: error.errorMessage,
                                    SCMethodParams.errorDescription.rawValue: error.errorDescription]
                    self?.channel?.invokeMethod(SCMethodParams.ON_SIGNED_CALL_DID_INITIALIZE.rawValue, arguments: errorObj)
                    result(nil)
                }
            }
        }
    }
    
    func makeCall(_ callData:[String: Any], result: @escaping FlutterResult) {
        guard let context = callData[SCMethodParams.CONTEXT.rawValue] as? String,
              let receiverCuid = callData[SCMethodParams.RECEIVERCUID.rawValue] as? String else {
            os_log("Handle flutter method CALL, key: callContext and receiverCuid not available", log: logValue, type: .default)
            result(nil)
            return
        }
        
        var customMetaData: SCCustomMetadata?
        if let callOptions = callData[SCMethodParams.CALLOPTIONS.rawValue] as? [String: String] {
            let remoteContext = callOptions[SCMethodParams.REMOTE_CONTEXT.rawValue]
            let initiatorImage = callOptions[SCMethodParams.INITIATORIMG.rawValue]
            let receiverImage = callOptions[SCMethodParams.RECEIVERIMG.rawValue]
            customMetaData = SCCustomMetadata(remoteContext: remoteContext, initiatorImage: initiatorImage, receiverImage: receiverImage)
        }
        
        let callOptionsModel = SCCallOptionsModel(context: context, receiverCuid: receiverCuid, customMetaData: customMetaData)
        
        SignedCall.call(callOptions: callOptionsModel) { [weak self] res in
            DispatchQueue.main.async {
                switch res {
                case .success(_):
                    self?.channel?.invokeMethod(SCMethodParams.ON_SIGNED_CALL_DID_VOIP_CALL_INITIATE.rawValue, arguments: nil)
                    result(nil)
                case .failure(let error):
                    let errorObj = [SCMethodParams.errorCode.rawValue: error.errorCode,
                                    SCMethodParams.errorMessage.rawValue: error.errorMessage,
                                    SCMethodParams.errorDescription.rawValue: error.errorDescription]
                    self?.channel?.invokeMethod(SCMethodParams.ON_SIGNED_CALL_DID_VOIP_CALL_INITIATE.rawValue, arguments: errorObj)
                    result(nil)
                }
            }
        }
    }
    
    @objc func callStatus(notification: Notification) {
        let callDetails = notification.userInfo?["callDetails"] as? SCCallStatusDetails
        
        let status: SCCallStatus? = callDetails?.status
        let callDirection: String = "\(callDetails?.callDirection.rawValue ?? "")"
        let calleeCuid: String = "\(callDetails?.callDetails.calleeCuid ?? "")"
        let callerCuid: String = "\(callDetails?.callDetails.callerCuid ?? "")"
        let initiatorImage: String = "\(callDetails?.callDetails.initiatorImage ?? "")"
        let receiverImage: String = "\(callDetails?.callDetails.receiverImage ?? "")"
        let callContext: String = "\(callDetails?.callDetails.context ?? "")"
        
        let callDetailsDict: [String : Any] = ["direction": callDirection.uppercased(),
                                               "callDetails": ["callerCuid": callerCuid, "calleeCuid": calleeCuid, "callContext": callContext, "initiatorImage": initiatorImage, "receiverImage": receiverImage],
                                               "callEvent": SCCallEventMapping(callStatus: status).value]
        handleCallEvent(callDetailsDict)
    }
    
    func handleCallEvent(_ callDetails: [String: Any]) {
        do {
            try callEventTrigger?.success(event: callDetails)
        } catch {
            os_log("Handle call event error: %{public}@", log: logValue, type: .default, error.localizedDescription)
            callEventTrigger?.error(
                code: "Call event handling error",
                message: error.localizedDescription
            )
        }
    }
}
