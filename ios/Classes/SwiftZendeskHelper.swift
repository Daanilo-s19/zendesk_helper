import os.log
import Flutter
import UIKit
import ChatSDK
import ChatProvidersSDK
import CommonUISDK
import MessagingSDK


public class SwiftZendeskHelper: NSObject, FlutterPlugin {
    var chatAPIConfig: ChatAPIConfiguration?
    let navController = UINavigationController()
    let rootViewController = UIApplication.shared.windows.filter({ (w) -> Bool in
        return w.isHidden == false
    }).first?.rootViewController
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "zendesk", binaryMessenger: registrar.messenger())
        let instance = SwiftZendeskHelper()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let dic = call.arguments as? Dictionary<String, Any>
        
        switch call.method {
        case "getPlatformVersion":
            result("iOS yo " + UIDevice.current.systemVersion)
        case "initialize":
            initialize(dictionary: dic!)
            result(true)
        case "setVisitorInfo":
            setVisitorInfo(dictionary: dic!)
            result(true)
        case "startChat":
            do {
                try startChat(dictionary: dic!)
            } catch _ {
                os_log("error:")
            }
            result(true)
        case "addTags":
            addTags(dictionary: dic!)
            result(true)
        case "removeTags":
            removeTags(dictionary: dic!)
            result(true)
        case "sendMessage":
            sendMessage(dictionary: dic!)
            result(true)
        case "endChat":
            let isChatting = endChat { endChatResult in
                switch endChatResult {
                case .success:
                    result(true)
                case .failure(let error):
                    result(FlutterError(code: "endChat", message: error.localizedDescription, details: "Failed endChat \(error)"))
                }
            }
            if(!isChatting) {
                result(true)
            }
        case "registerPushToken":
            registerPushToken(dictionary: dic!, flutterResult: result)
        case "unregisterPushToken":
            result(unregisterPushToken())
        default:
            result("iOS " + UIDevice.current.systemVersion)
        }
    }
    
    func initialize(dictionary: Dictionary<String, Any>) {
        guard let accountKey = dictionary["accountKey"] as? String,
              let appId = dictionary["appId"] as? String
        else { return }
        
        Chat.initialize(accountKey: accountKey, appId: appId)
        initChatConfig()
    }
    
    func setVisitorInfo(dictionary: Dictionary<String, Any>) {
        guard let name = dictionary["name"] as? String,
              let email = dictionary["email"] as? String,
              let phoneNumber = dictionary["phoneNumber"] as? String
        else { return }
        let department = dictionary["department"] as? String ?? ""
        chatAPIConfig?.departmentName = department
        chatAPIConfig?.visitorInfo = VisitorInfo(name: name, email: email, phoneNumber: phoneNumber)
        Chat.instance?.configuration = chatAPIConfig!
    }
    
    func addTags(dictionary: Dictionary<String, Any>) {
        let tags = dictionary["tags"] as? Array<String> ?? []
        chatAPIConfig?.tags.append(contentsOf: tags)
        Chat.instance?.configuration = chatAPIConfig!
    }
    
    func removeTags(dictionary: Dictionary<String, Any>) {
        let tags = dictionary["tags"] as? Array<String> ?? []
        chatAPIConfig?.tags.removeAll(where: { t  in return tags.contains(t) })
        Chat.instance?.configuration = chatAPIConfig!
    }
    
    @objc
    func backButton(){
        navController.dismiss(animated: true)
    }
    
    func startChat(dictionary: Dictionary<String, Any>) throws {
        guard let isPreChatFormEnabled = dictionary["isPreChatFormEnabled"] as? Bool,
              let isPreChatEmailField = dictionary["isPreChatEmailField"] as? Bool,
              let isPreChatNameField = dictionary["isPreChatNameField"] as? Bool,
              let isPreChatPhoneField = dictionary["isPreChatPhoneField"] as? Bool,
              let isAgentAvailabilityEnabled = dictionary["isAgentAvailabilityEnabled"] as? Bool,
              let isChatTranscriptPromptEnabled = dictionary["isChatTranscriptPromptEnabled"] as? Bool,
              let isOfflineFormEnabled = dictionary["isOfflineFormEnabled"] as? Bool,
              let disableEndChatMenuAction = dictionary["disableEndChatMenuAction"] as? Bool
                
        else {return}
        if let primaryColor = dictionary["primaryColor"] as? Int {
            CommonTheme.currentTheme.primaryColor = uiColorFromHex(rgbValue: primaryColor)
        }
        // Name for Bot messages
        let messagingConfiguration = MessagingConfiguration()
        messagingConfiguration.name = dictionary["botName"] as? String ?? "Answer Bot"
        
        let formConfiguration =  ChatFormConfiguration(name: isPreChatNameField ? .optional : .hidden,
                                                       email: isPreChatEmailField ? .optional : .hidden,
                                                       phoneNumber: isPreChatPhoneField ? .optional : .hidden)
        
        let chatMenuActions = disableEndChatMenuAction ?  [] : [.emailTranscript, .endChat] as Array<ChatMenuAction>         
        // Chat configuration
        let chatConfiguration = ChatConfiguration()
        chatConfiguration.isPreChatFormEnabled = isPreChatFormEnabled
        chatConfiguration.preChatFormConfiguration = formConfiguration
        chatConfiguration.isAgentAvailabilityEnabled = isAgentAvailabilityEnabled
        chatConfiguration.isChatTranscriptPromptEnabled = isChatTranscriptPromptEnabled
        chatConfiguration.isOfflineFormEnabled = isOfflineFormEnabled
        chatConfiguration.chatMenuActions =  chatMenuActions
        
        // Build view controller
        let chatEngine = try ChatEngine.engine()
        let viewController = try Messaging.instance.buildUI(engines: [chatEngine], configs: [messagingConfiguration, chatConfiguration])
        
        navController.viewControllers = [viewController]
        
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: dictionary["close"] as? String ?? "Fechar", style: .plain, target: self, action: #selector(backButton))
        viewController.title = dictionary["title"] as? String ?? "Suporte"
        if let theme = dictionary["isDarkTheme"] as? Bool {
            if #available(iOS 13.0, *) {
                viewController.overrideUserInterfaceStyle = theme ? .dark : .light
            } else {
                // Fallback on earlier versions
            }
        }

        presentViewController(view: navController);
    }
    
    
    func presentViewController(view: UIViewController) {
        if(view.isBeingPresented) {
            return
        }
        
        if var topController = UIApplication.shared.keyWindow?.rootViewController  {
                       while let presentedViewController = topController.presentedViewController {
                             topController = presentedViewController
                            }
                 topController.present(view, animated: true, completion: nil)
        }
    }

    func uiColorFromHex(rgbValue: Int) -> UIColor {
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue =  CGFloat(rgbValue & 0x0000FF) / 255.0
        let alpha = CGFloat(1.0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func initChatConfig() {
        if (chatAPIConfig == nil) {
            chatAPIConfig = ChatAPIConfiguration()
        }
    }


    func sendMessage(dictionary: Dictionary<String, Any>) {
        guard let message = dictionary["message"] as? String
        else { return }
        
        Chat.instance?.chatProvider.sendMessage(message)
    }

    private func endChat(completionHandler: @escaping ((Result<Bool, DeliveryStatusError>) -> Void)) -> Bool {
        guard let chatProvider = Chat.instance?.chatProvider,
          chatProvider.chatState.isChatting else {
            return false
        }

        chatProvider.endChat(completionHandler)
        return true
    }
    
    private func registerPushToken(dictionary: Dictionary<String, Any>, flutterResult: FlutterResult) {
        guard let pushProvider = Chat.instance?.pushNotificationsProvider,
            let pushToken = dictionary["pushToken"] as? String else {
            flutterResult(FlutterError(code: "pushToken", message: "pushToken is nil", details: nil))
            return
        }

        pushProvider.registerPushTokenString(pushToken)
        flutterResult(true)
    }
    
    private func unregisterPushToken() {
        guard let pushProvider = Chat.instance?.pushNotificationsProvider else {
            return
        }
        pushProvider.unregisterPushToken()
    }
}
