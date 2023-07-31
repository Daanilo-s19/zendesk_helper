import os.log
import Flutter
import UIKit
import ChatSDK
import ChatProvidersSDK
import CommonUISDK
import MessagingSDK


public class SwiftZendeskHelper: NSObject, FlutterPlugin {
    var chatAPIConfig: ChatAPIConfiguration?
    
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
    
    func startChat(dictionary: Dictionary<String, Any>) throws {
        guard let isPreChatFormEnabled = dictionary["isPreChatFormEnabled"] as? Bool,
              let isAgentAvailabilityEnabled = dictionary["isAgentAvailabilityEnabled"] as? Bool,
              let isChatTranscriptPromptEnabled = dictionary["isChatTranscriptPromptEnabled"] as? Bool,
              let isOfflineFormEnabled = dictionary["isOfflineFormEnabled"] as? Bool
                
        else {return}
        if let primaryColor = dictionary["primaryColor"] as? Int {
            CommonTheme.currentTheme.primaryColor = uiColorFromHex(rgbValue: primaryColor)
        }
        // Name for Bot messages
        let messagingConfiguration = MessagingConfiguration()
        messagingConfiguration.name = dictionary["botName"] as? String ?? "Answer Bot"
        
        // Chat configuration
        let chatConfiguration = ChatConfiguration()
        chatConfiguration.isPreChatFormEnabled = isPreChatFormEnabled
        chatConfiguration.isAgentAvailabilityEnabled = isAgentAvailabilityEnabled
        chatConfiguration.isChatTranscriptPromptEnabled = isChatTranscriptPromptEnabled
        chatConfiguration.isOfflineFormEnabled = isOfflineFormEnabled
        
        // Build view controller
        let chatEngine = try ChatEngine.engine()
        let viewController = try Messaging.instance.buildUI(engines: [chatEngine], configs: [messagingConfiguration, chatConfiguration])
        viewController.title = "Contact Us"
        if let theme = dictionary["isDarkTheme"] as? Bool {
            if #available(iOS 13.0, *) {
                viewController.overrideUserInterfaceStyle = theme ? .dark : .light
            } else {
                // Fallback on earlier versions
            }
        }

        // Present view controller
        let rootViewController = UIApplication.shared.windows.filter({ (w) -> Bool in
            return w.isHidden == false
        }).first?.rootViewController
        presentViewController(rootViewController: rootViewController, view: viewController);
    }
    
    
    func presentViewController(rootViewController: UIViewController?, view: UIViewController) {
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
}
