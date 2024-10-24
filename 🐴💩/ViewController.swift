//
//  ViewController.swift
//  🐴💩
//
//  Created by Goomba on 2024-01-19.
//

import UIKit
import Vision
import CoreML
import Foundation
import SwiftSoup
import TLDExtractSwift

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var pictureBox: UIImageView!
    
    @IBOutlet weak var url: UITextView!
    
    @IBOutlet weak var photoLibrary: UIButton!
    
    @IBOutlet weak var information: UIButton!
    
    var inputImage:CIImage?
    
    var recognizedWords:[String] = [String]()
    
    var recognizedRegion:String = String()
    
    var absoluteURL:Substring?
    
    var constructedURL: String?
    
    var finishedURL = false
    
    var urlConstructCount = 0
    
    var urlCount = 0
    
    var matched = false
    
    var urlArray: [String] = []
    
    var foundStringURL = false
    
    private var imageChangeObservation: NSKeyValueObservation?
    
    var proxy: Proxy?
    
    struct Proxy
    {
        var ip: String
        var port: String
    }
    
    //TEXT-DETECTION-REQUEST
    lazy var textDetectionRequest: VNRecognizeTextRequest = {
        return VNRecognizeTextRequest(completionHandler: self.detectTextHandler)
    }()
    
    private func detectTextHandler(request: VNRequest, error: Error?)
    {
        let extractor = try! TLDExtract(useFrozenData: true)
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else
        {
            fatalError("Received invalid observations")
        }
        
        for lineObservation in observations
        {
            guard let textLine = lineObservation.topCandidates(1).first else
            { 
                continue
            }
            
            let words = textLine.string.split{ $0.isWhitespace }.map{ String($0)}
            for word in words
            {
                if let wordRange = textLine.string.range(of: word)
                {
                    if (try? textLine.boundingBox(for: wordRange)?.boundingBox) != nil
                    {
                        if let possibleURL = URL(string: word)
                        {
                            Swift.print("Possible constructed URL: \(possibleURL)")
                            
                            // get TLD and search in contains
                            //https://github.com/gumob/TLDExtractSwift
                            
                            //possibleURL.absoluteString.range(of: ".coU") != nil ||
                            /*if (possibleURL.absoluteString.contains("http") ||
                                possibleURL.absoluteString.contains("https") ||
                                possibleURL.absoluteString.contains("www.") || 
                                possibleURL.absoluteString.contains(".com") ||
                                possibleURL.absoluteString.contains(".coU") ||
                                possibleURL.absoluteString.contains(".co") || 
                                possibleURL.absoluteString.contains(".cU") ||
                                possibleURL.absoluteString.contains(".net") ||
                                possibleURL.absoluteString.contains(".neU") ||
                                possibleURL.absoluteString.contains(".ca") ||
                                possibleURL.absoluteString.contains(".org") ||
                                possibleURL.absoluteString.contains(".edu") ||
                                possibleURL.absoluteString.contains(".gov") ||
                                possibleURL.absoluteString.contains(".store"))*/
                            
                            if let possibleURLResult = extractor.parse(possibleURL)
                            {
                                if possibleURLResult.subDomain != nil || possibleURLResult.topLevelDomain != nil && possibleURL.absoluteString.contains(possibleURLResult.subDomain ?? "") || possibleURL.absoluteString.contains(possibleURLResult.topLevelDomain ?? "")
                                {
                                    Swift.print("Possible constructed URL subDomain: \(possibleURLResult.subDomain ?? "MISSING") & Possible constructed URL topLevelDomain: \(possibleURLResult.topLevelDomain ?? "MISSING")")
                                    
                                    if (possibleURL.absoluteString.range(of: "icloud.com") == nil)
                                    {
                                        if (possibleURL.absoluteString.decomposedStringWithCompatibilityMapping.compare("@", options: .caseInsensitive) == .orderedDescending)
                                        {
                                            var stringURL = possibleURL.absoluteString
                                            
                                            Swift.print("URL may contain mismatch topLevelDomain: \(stringURL)")
                                            
                                            if (stringURL.contains(".neU"))
                                            {
                                                stringURL = (stringURL as NSString).replacingOccurrences(of: ".neU", with: ".net/")
                                            }
                                            else if (stringURL.contains(".coU"))
                                            {
                                                stringURL = (stringURL as NSString).replacingOccurrences(of: ".coU", with: ".com/")
                                            }
                                            else if (stringURL.contains(".cU"))
                                            {
                                                stringURL = (stringURL as NSString).replacingOccurrences(of: ".cU", with: ".co/")
                                            }
                                            
                                            let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                                            let matches = detector.matches(in: stringURL, options: [], range: NSRange(location: 0, length: stringURL.utf16.count))
                                            
                                            for match in matches
                                            {
                                                self.foundStringURL = true
                                                
                                                guard let range = Range(match.range, in: stringURL) else { continue }
                                                self.absoluteURL = stringURL[range]
                                                
                                                if let possibleAbsoluteURL = URL(string: String(self.absoluteURL!))
                                                {
                                                    Swift.print("Possible constructed absolute URL: \(possibleAbsoluteURL)")
                                                    
                                                    /*if (possibleAbsoluteURL.absoluteString.contains(".com") || possibleAbsoluteURL.absoluteString.contains(".co") || possibleAbsoluteURL.absoluteString.contains(".net") ||
                                                     possibleAbsoluteURL.absoluteString.contains(".ca") ||
                                                     possibleAbsoluteURL.absoluteString.contains(".edu") ||
                                                     possibleAbsoluteURL.absoluteString.contains(".gov") ||
                                                     possibleAbsoluteURL.absoluteString.contains(".org") ||
                                                     possibleAbsoluteURL.absoluteString.contains(".store"))*/
                                                    
                                                    if let possibleAbsoluteURLResult = extractor.parse(possibleAbsoluteURL)
                                                    {
                                                        if possibleAbsoluteURLResult.topLevelDomain != nil && possibleAbsoluteURL.absoluteString.contains(possibleAbsoluteURLResult.topLevelDomain ?? "")
                                                        {
                                                            Swift.print("Possible constructed absolute URL topLevelDomain: \(possibleURLResult.topLevelDomain ?? "MISSING")")
                                                            
                                                            if (self.urlConstructCount == 0)
                                                            {
                                                                if let constructedURL = self.constructedURL, !constructedURL.isEmpty
                                                                {
                                                                    self.constructedURL?.removeAll(keepingCapacity: false)
                                                                }
                                                                
                                                                self.constructedURL = String(stringURL[range])
                                                                
                                                                Swift.print("Constructed URL: \(constructedURL!)")
                                                            }
                                                            else
                                                            {
                                                                self.constructedURL!.append(contentsOf: stringURL[range])
                                                            }
                                                            
                                                            self.finishedURL = true
                                                        }
                                                        else
                                                        {
                                                            if let constructedURL = self.constructedURL, !constructedURL.isEmpty
                                                            {
                                                                self.constructedURL?.removeAll(keepingCapacity: false)
                                                            }
                                                            
                                                            self.constructedURL = String(stringURL[range])
                                                            
                                                            Swift.print("Constructed URL: \(constructedURL!)")
                                                        }
                                                    }
                                                    
                                                    self.urlConstructCount+=1
                                                    
                                                    if (self.urlConstructCount >= 1 && self.finishedURL)
                                                    {
                                                        self.urlCount += 1
                                                        
                                                        self.urlConstructCount = 0
                                                        
                                                        DispatchQueue.main.async
                                                        {
                                                            if !self.urlArray.contains(self.constructedURL!)
                                                            {
                                                                self.urlArray.append(self.constructedURL!)
                                                                
                                                                if self.urlCount > self.urlArray.count
                                                                {
                                                                    self.urlCount -= 1
                                                                }
                                                                
                                                                self.url.text?.append("\(self.urlCount). \(self.constructedURL!)\n")
                                                            }
                                                            else
                                                            {
                                                                self.urlCount -= 1
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            if (!self.foundStringURL)
                                            {
                                                Swift.print("HAVENT FOUND URL")
                                                
                                                if let possibleURL = URL(string: stringURL)
                                                {
                                                    Swift.print("Possible URL: \(possibleURL)")
                                                    
                                                    /*if (possibleURL.absoluteString.contains(".com") ||
                                                     possibleURL.absoluteString.contains(".co") ||
                                                     possibleURL.absoluteString.contains(".net") ||
                                                     possibleURL.absoluteString.contains(".ca") ||
                                                     possibleURL.absoluteString.contains(".edu") ||
                                                     possibleURL.absoluteString.contains(".gov") ||
                                                     possibleURL.absoluteString.contains(".org") ||
                                                     possibleURL.absoluteString.contains(".store"))*/
                                                    
                                                    if let possibleURLResult = extractor.parse(possibleURL)
                                                    {
                                                        if possibleURLResult.topLevelDomain != nil && possibleURL.absoluteString.contains(possibleURLResult.topLevelDomain ?? "")
                                                        {
                                                            Swift.print("Possible URL topLevelDomain: \(possibleURLResult.topLevelDomain ?? "MISSING")")
                                                            
                                                            if (self.urlConstructCount == 0)
                                                            {
                                                                if let constructedURL = self.constructedURL, !constructedURL.isEmpty
                                                                {
                                                                    self.constructedURL?.removeAll(keepingCapacity: false)
                                                                }
                                                                
                                                                self.constructedURL = String(stringURL)
                                                            }
                                                            else
                                                            {
                                                                self.constructedURL!.append(stringURL)
                                                            }
                                                            
                                                            self.finishedURL = true
                                                        }
                                                        else
                                                        {
                                                            if let constructedURL = self.constructedURL, !constructedURL.isEmpty
                                                            {
                                                                self.constructedURL?.removeAll(keepingCapacity: false)
                                                            }
                                                            
                                                            self.constructedURL = String(stringURL)
                                                            
                                                            Swift.print("Constructed URL: \(constructedURL!)")
                                                        }
                                                    }
                                                    
                                                    self.urlConstructCount+=1
                                                    
                                                    if (self.urlConstructCount >= 1 && self.finishedURL)
                                                    {
                                                        self.urlCount += 1
                                                        
                                                        self.urlConstructCount = 0
                                                        
                                                        DispatchQueue.main.async
                                                        {
                                                            self.urlArray.append(self.constructedURL!)
                                                            
                                                            self.url.text?.append("\(self.urlCount). \(self.constructedURL!)\n")
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            self.foundStringURL = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func verifyURL()
    {
        var url = 0
        let group = DispatchGroup()
        
        while url <= self.urlArray.count - 1
        {
            if url <= self.urlArray.count - 1
            {
                if let finalURL = self.extractURL(from: self.urlArray[url])
                {
                    group.enter()
                    
                    self.scrapeGoogleSearchResults(query: finalURL) { results in
                        do
                        {
                            let jsonData = try JSONSerialization.data(withJSONObject: results, options: .prettyPrinted)
                            if let jsonString = String(data: jsonData, encoding: .utf8)
                            {
                                print(jsonString)
                                
                                if let jsonArray = results as? [[String: Any]]
                                {
                                    // ACCELERATIONIST UPDATE 3.0 AFTER DEMO :O
                                    
                                    let ogConstructedURLDomain = self.extractDomain(from: finalURL)
                                    let removeURLPrefixConstructedURLDomain = self.removeURLPrefixes(ogConstructedURLDomain!)
                                    let ignoreAfterDomainConstructedURLDomain = removeURLPrefixConstructedURLDomain.ignoreAfterDomain()
                                    
                                    let pattern = "\(NSRegularExpression.escapedPattern(for: ignoreAfterDomainConstructedURLDomain))|scam|Scam|fradulent|Fradulent|malicious|Malicious"
                                    let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                                    
                                    let bFoundTitle = jsonArray.contains
                                    { entryTitle -> Bool in
                                        if let title = entryTitle["title"] as? String
                                        {
                                            let range = NSRange(location: 0, length: title.utf16.count)
                                            return regex.firstMatch(in: title, options: [], range: range) != nil
                                        }
                                        return false
                                    }
                                    
                                    for entry in jsonArray
                                    {
                                        let ogLinks = entry["links"] as? String
                                        let removeURLPrefixLinks = self.removeURLPrefixes(ogLinks!)
                                        let ignoreAfterDomainLinks = removeURLPrefixLinks.ignoreAfterDomain()

                                        if let URL = URL(string: ignoreAfterDomainLinks)
                                        {
                                            //if (URL.absoluteString.range(of: ignoreAfterDomainConstructedURLDomain) != nil ||
                                                //URL.absoluteString.range(of: self.urlArray[url]) != nil)
                                            if (URL.absoluteString.contains(ignoreAfterDomainConstructedURLDomain) ||
                                                URL.absoluteString.contains(self.urlArray[url]))
                                            {
                                                if(ignoreAfterDomainConstructedURLDomain.decomposedStringWithCompatibilityMapping.compare(URL.absoluteString, options: .caseInsensitive) != .orderedDescending || self.urlArray[url].decomposedStringWithCompatibilityMapping.compare(URL.absoluteString, options: .caseInsensitive) != .orderedDescending)
                                                {
                                                    if (URL.absoluteString.decomposedStringWithCompatibilityMapping.compare("script.google.com/macros/s/", options: .caseInsensitive) != .orderedSame ||
                                                        URL.absoluteString.decomposedStringWithCompatibilityMapping.compare("canadapost-mydelivery.com/cap", options: .caseInsensitive) != .orderedSame ||
                                                        URL.absoluteString.decomposedStringWithCompatibilityMapping.compare("tinyurl.com", options: .caseInsensitive) != .orderedSame)
                                                    {
                                                        if (!bFoundTitle)
                                                        {
                                                            print("No scam URL found: \(finalURL)")
                                                            
                                                            self.matched = true
                                                            
                                                            break
                                                        }
                                                        else
                                                        {
                                                            print("Scam URL found: \(finalURL)")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                DispatchQueue.main.async
                                {
                                    if (self.matched)
                                    {
                                        var lines = self.url.text.components(separatedBy: CharacterSet.newlines)
                                        
                                        lines[url] = "\(self.urlArray[url]) is 🙏"
                                        
                                        let updatedText = lines.joined(separator: "\n")
                                        
                                        self.url.text = updatedText
                                        
                                        self.matched = false
                                        
                                        url += 1
                                        
                                        group.leave()
                                    }
                                    else
                                    {
                                        
                                        var lines = self.url.text.components(separatedBy: CharacterSet.newlines)
                                        
                                        lines[url] = "\(self.urlArray[url]) is 🐴💩"
                                        
                                        let updatedText = lines.joined(separator: "\n")
                                        
                                        self.url.text = updatedText
                                        
                                        url += 1
                                        
                                        group.leave()
                                    }
                                }
                            }
                        }
                        catch
                        {
                            print("Error converting data to JSON: \(error)")
                        }
                    }
                }
            }
            
            group.wait()
        }
        
        DispatchQueue.main.async
        {
            if self.urlArray.count == 0
            {
                self.url.text = "NOTHING DETECTED"
            }
        }
    }
    
    func fetchProxies(from url: String, completion: @escaping ([Proxy]) -> Void) 
    {
        guard let url = URL(string: url) else 
        {
           print("Invalid URL")
            return
        }
    
        let task = URLSession.shared.dataTask(with: url) 
        { data, response, error in
            
            if let error = error
            {
                print("Error fetching data: \(error)")
                completion([])
                return
            }
    
            guard let data = data, let content = String(data: data, encoding: .utf8) else 
            {
                print("No data or unable to decode data")
                completion([])
                return
            }
    
           let proxies = content.split(separator: "\n").compactMap 
            { line -> Proxy? in
                let components = line.split(separator: ":")
                guard components.count == 2 else { return nil }
                return Proxy(ip: String(components[0]), port: String(components[1]))
            }
    
            completion(proxies)
        }
    
        task.resume()
    }
    
    func scrapeGoogleSearchResults(query: String, language: String = "en", country: String = "us", completion: @escaping ([[String: Any]]) -> Void) {
        let baseURL = URL(string: "https://www.google.com/search")!
        
        var headers = [
            // Existing user agents
            "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Safari/605.1.15",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:77.0) Gecko/20100101 Firefox/77.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:77.0) Gecko/20100101 Firefox/77.0",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_5_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/92.0.902.78",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.71 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.71 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko",
            "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:100.0) Gecko/20100101 Firefox/100.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Edge/94.0.992.50 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36",
            // Non-Mozilla user agents
            "Opera/9.80 (Windows NT 6.1; WOW64) Presto/2.12.388 Version/12.18",
            "Safari/537.36 (KHTML, like Gecko) Chrome/99.0.9999.99 Mobile/15A372",
            "Googlebot/2.1 (+http://www.google.com/bot.html)",
            "IE/9.0 (Windows NT 6.1; WOW64; Trident/5.0)",
            "Microsoft Office/16.0 (Windows NT 10.0; Microsoft Outlook 16.0.10366; Pro)",
            "Curl/7.79.1",
        ]
        
        var pageNum = 0
        var resultData: [[String: Any]] = []
        
        func fetchDataAndParse(params: [String: String])
        {
            var params = params
            
            print("page: \(pageNum)")
            
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            
            guard let url = components.url else {
                print("Error creating URL.")
                return
            }
            
            var request = URLRequest(url: url)
            
            let user_agent = headers.randomElement()!
            request.setValue(user_agent, forHTTPHeaderField: "User -Agent")

            let proxyHost = proxy!.ip
            let proxyPort = proxy!.port
            
            let config = URLSessionConfiguration.default
            config.connectionProxyDictionary =
            [
                kCFNetworkProxiesHTTPProxy as String: proxyHost,
                kCFNetworkProxiesHTTPPort as String: proxyPort
            ]
            
            let session = URLSession(configuration: config)
            
            let task = URLSession.shared.dataTask(with: request)
            { data, response, error in
                
                guard let data = data, error == nil else
                {
                    print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                do 
                {
                    let html = try String(data: data, encoding: .utf8)
                    let soup = try SwiftSoup.parse(html ?? "")
                    
                    for result in try soup.select(".tF2Cxc") {
                        let title = try result.select(".DKV0Md").text()
                        let snippet = try? result.select(".lEBKkf span").text()
                        let links = try result.select(".yuRUbf a").attr("href")
                        
                        let entry: [String: Any] = [
                            "title": title,
                            "snippet": snippet ?? "",
                            "links": links
                        ]
                        
                        resultData.append(entry)
                    }
                    
                    do 
                    {
                        if let selection = try soup.select(".d6cvqb a[id=pnnext]").first() 
                        {
                            if let startValue = Int(params["start"] ?? "0") 
                            {
                                pageNum += 1
                                params["start"] = "\(startValue + pageNum + 10)"
                                fetchDataAndParse(params: params)
                            } 
                            else
                            {
                                completion(resultData)
                            }
                        } 
                        else
                        {
                            completion(resultData)
                        }
                    } 
                    catch
                    {
                        // Handle any errors that may occur during HTML parsing
                        print("Error: \(error)")
                        completion(resultData)
                    }
                }
                catch
                {
                    print("Error parsing HTML: \(error)")
                    completion([])
                }
            }
            
            task.resume()
        }
        
        fetchDataAndParse(params: ["q": query, "hl": language, "gl": country, "start": "0"])
    }
    
    func doOCR(ciImage: CIImage, completion: @escaping (Result<[VNRecognizedTextObservation], Error>) -> Void) {
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        self.textDetectionRequest.recognitionLevel = .accurate
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([self.textDetectionRequest])
                if let observations = self.textDetectionRequest.results as? [VNRecognizedTextObservation] {
                    completion(.success(observations))
                } else {
                    let error = NSError(domain: "YourErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid observations"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
                return
            }
        }
    }
    
    func extractURL(from input: String) -> String? {
        let pattern = "(https?://)?(www\\.)?([\\w-]+(\\.[\\w-]+)+)(/\\S*)?"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                return String(input[Range(match.range, in: input)!])
            }
        } catch {
            print("Error creating regex: \(error)")
        }
        
        return nil
    }
    
    func extractDomain(from url: String) -> String? {
        guard let parsedURL = URL(string: url),
              let host = parsedURL.host else {
            return url
        }
        
        return host
    }
    
    func removeURLPrefixes(_ input: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: "^(https?://)?(www\\.)?", options: .caseInsensitive)
            let range = NSRange(location: 0, length: input.utf16.count)
            return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
        } catch {
            print("Error creating regex: \(error.localizedDescription)")
            return input
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let proxyURL = "https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/http.txt"
        
        imageChangeObservation = self.pictureBox.observe(\.image, options: [.new])
        { [weak self] (object, change) in
            
            self!.fetchProxies(from: proxyURL)
            { proxies in
                DispatchQueue.main.async
                {
                    self!.proxy = proxies.randomElement()!
                    
                    self!.photoLibrary.isEnabled = true
                    
                    self!.url.text = nil
                    
                    self!.recognizedWords.removeAll(keepingCapacity: false)
                   
                    self!.recognizedRegion.removeAll(keepingCapacity: false)
                    
                    self!.absoluteURL = nil
                    
                    self!.constructedURL = nil
                    
                    self!.finishedURL = false
                    
                    self!.urlConstructCount = 0
                    
                    self!.urlCount = 0
                    
                    self!.matched = false
                    
                    self!.urlArray.removeAll(keepingCapacity: false)
                    
                    let loadedImage:UIImage = self!.pictureBox.image!

                    self!.inputImage = CIImage(image:loadedImage)!
                    
                    self!.executeOCR(image: self!.inputImage!)
                }
            }
        }
        
        fetchProxies(from: proxyURL) 
        { proxies in
            DispatchQueue.main.async
            {
                self.proxy = proxies.randomElement()!
                
                self.photoLibrary.isEnabled = true
            }
        }
    }
    
    func executeOCR(image: CIImage)
    {
        self.doOCR(ciImage: image)
        { result in
            switch result
            {
            case .success(let observations):
                self.verifyURL()
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func informationPicker(_ sender: Any)
    {
        let alert = UIAlertController(title: "Information", message: "Created by: Andrew Justin Solesa", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    

    @IBAction func imagePicker(_ sender: Any) 
    {
        let picker = UIImagePickerController()
        
        picker.allowsEditing = true
        
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {return}
        
        self.pictureBox.image = image
        
        dismiss(animated: true)
    }
}

private extension String {
    var words: Set<String> {
        return Set(components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
    }

    func containsWords(of string: String) -> Bool {
        return words.isSuperset(of: string.words)
    }
}

extension String {
    func firstIndex(of character: Character, startingFrom index: String.Index) -> String.Index? {
        var currentIndex = index
        while currentIndex < endIndex {
            if self[currentIndex] == character {
                return currentIndex
            }
            currentIndex = self.index(after: currentIndex)
        }
        return nil
    }
}

extension String {
    func ignoreAfterDomain() -> String
    {
        let existingDomainExtensions = "\\.com$|\\.net$|\\.ca$|\\.co$|\\.il"

        let combinedDomainExtensions = "\(existingDomainExtensions)|\\.(?:[a-z]{2,}|co\\.[a-z]{2})$"

        do
        {
            let regex = try NSRegularExpression(pattern: combinedDomainExtensions, options: .caseInsensitive)

            let range = NSRange(location: 0, length: self.utf16.count)
            let matchRange = regex.rangeOfFirstMatch(in: self, options: [], range: range)

            if matchRange.location != NSNotFound 
            {
                if let matchStringRange = Range(matchRange, in: self) 
                {
                    let searchRange = matchStringRange.upperBound..<self.endIndex
                    if let nextSlashRange = self.range(of: "/", options: [], range: searchRange, locale: nil) 
                    {
                        let result = self[..<nextSlashRange.lowerBound]
                        return String(result)
                    }
                }
            }
        } 
        catch
        {
            print("Error creating regular expression: \(error)")
        }
        return self
    }
}

