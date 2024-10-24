//
//  ViewController.swift
//  🐴💩
//
//  Created by Process Fusion on 2024-01-19.
//

import UIKit
import Vision
import CoreML
import Foundation
import SwiftSoup

class ViewController: UIViewController {

    //HOLDS OUR INPUT
    var  inputImage:CIImage?
    
    //RESULT FROM OVERALL RECOGNITION
    var  recognizedWords:[String] = [String]()
   
    //RESULT FROM RECOGNITION
    var recognizedRegion:String = String()
    
    @IBOutlet weak var pictureBox: UIImageView!
    
    @IBOutlet weak var url: UITextView!
    
    var absoluteURL:Substring?
    
    var constructedURL: String?
    
    var finishedURL = false
    
    var urlConstructCount = 0
    
    var urlCount = 0
    
    var matched = false
    
    var urlArray: [String] = []
    
    //TEXT-DETECTION-REQUEST
    lazy var textDetectionRequest: VNRecognizeTextRequest = {
        return VNRecognizeTextRequest(completionHandler: self.detectTextHandler)
    }()

    private func detectTextHandler(request: VNRequest, error: Error?)
    {
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
                            if (possibleURL.absoluteString.range(of: "http") != nil || possibleURL.absoluteString.range(of: "https") != nil || possibleURL.absoluteString.range(of: "www.") != nil || possibleURL.absoluteString.range(of: ".com") != nil ||
                                possibleURL.absoluteString.range(of: ".coU") != nil ||
                                possibleURL.absoluteString.range(of: ".co") != nil || possibleURL.absoluteString.range(of: ".cU") != nil || possibleURL.absoluteString.range(of: ".net") != nil ||
                                possibleURL.absoluteString.range(of: ".neU") != nil
                            )
                            {
                                if (possibleURL.absoluteString.range(of: "icloud.com") == nil)
                                {
                                    var stringURL = possibleURL.absoluteString
                                
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
                                        guard let range = Range(match.range, in: stringURL) else { continue }
                                        self.absoluteURL = stringURL[range]
                                    
                                        if let possibleAbsoluteURL = URL(string: String(self.absoluteURL!))
                                        {
                                            if (possibleAbsoluteURL.absoluteString.range(of: ".com") != nil || possibleAbsoluteURL.absoluteString.range(of: ".co") != nil || possibleAbsoluteURL.absoluteString.range(of: ".net") != nil)
                                            {
                                                if (self.urlConstructCount == 0)
                                                {
                                                    self.constructedURL = String(stringURL[range])
                                                }
                                                else
                                                {
                                                    self.constructedURL!.append(contentsOf: stringURL[range])
                                                }
                                        
                                                self.finishedURL = true
                                            }
                                            else
                                            {
                                                self.constructedURL = String(stringURL[range])
                                            }
                                    
                                            self.urlConstructCount+=1
                                    
                                            if (self.urlConstructCount >= 1 && self.finishedURL)
                                            {
                                                self.urlCount+=1
                                        
                                                DispatchQueue.main.async
                                                {
                                                    self.urlArray.append(self.constructedURL!)
                                                    
                                                    self.url.text?.append("\(self.urlCount). \(self.constructedURL!)\n")
                                                    
                                                    self.urlConstructCount = 0
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
                    // Enter the group before calling the asynchronous function
                    group.enter()
                    
                    self.scrapeGoogleSearchResults(query: finalURL) { results in
                        do
                        {
                            let jsonData = try JSONSerialization.data(withJSONObject: results, options: .prettyPrinted)
                            if let jsonString = String(data: jsonData, encoding: .utf8)
                            {
                                print(jsonString)

                                // Compare domain of "links" with domain of self.constructedURL
                                if let jsonArray = results as? [[String: Any]]
                                {
                                    for entry in jsonArray
                                    {
                                        let links = entry["links"] as? String
                                        let constructedURLDomain = self.extractDomain(from: finalURL)
                                        
                                        if (links!.contains(constructedURLDomain!) || links!.contains(self.urlArray[url]))
                                        {
                                            if (!self.urlArray[url].contains("script.google.com/macros/s/") && !self.urlArray[url].contains("canadapost-mydelivery.com/cap"))
                                            {
                                                print("Match found: \(self.constructedURL!)")
                                    
                                                self.matched = true
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
    }
    
    func scrapeGoogleSearchResults(query: String, language: String = "en", country: String = "uk", completion: @escaping ([[String: Any]]) -> Void) {
        let baseURL = URL(string: "https://www.google.com/search")!
        var params = [
            "q": query,
            "hl": language,
            "gl": country,
            "start": "0"
        ]

        let headers = [
            "User-Agent": "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
        ]

        var pageNum = 0
        var resultData: [[String: Any]] = []

        func fetchDataAndParse() {
            pageNum += 1
            print("page: \(pageNum)")

            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

            guard let url = components.url else {
                print("Error creating URL.")
                return
            }

            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = headers

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }

                do {
                    let html = try String(data: data, encoding: .utf8)
                    let soup = try SwiftSoup.parse(html!)

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

                    if try soup.select(".d6cvqb a[id=pnnext]").count > 0 {
                        if let startValue = Int(params["start"] ?? "0") {
                            params["start"] = "\(startValue + 10)"
                            fetchDataAndParse()
                        } else {
                            completion(resultData)
                        }
                    } else {
                        completion(resultData)
                    }
                } catch {
                    print("Error parsing HTML: \(error)")
                    completion([])
                }
            }

            task.resume()
        }

        fetchDataAndParse()
    }
    
    func fetchHTML(from url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Set the User-Agent header
        request.addValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3538.102 Safari/537.36 Edge/18.19582", forHTTPHeaderField: "User-Agent")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                let dataError = NSError(domain: "com.example.FetchHTML", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse HTML data."])
                completion(.failure(dataError))
                return
            }

            completion(.success(html))
        }

        task.resume()
    }
    
    func doOCR(ciImage: CIImage, completion: @escaping (Result<[VNRecognizedTextObservation], Error>) -> Void) {
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        self.textDetectionRequest.recognitionLevel = .fast

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
        let pattern = "(https?://)?(www\\.)?[\\w-]+\\.(com|net|co|ca)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            
            if let match = regex.firstMatch(in: input, options: [], range: range) {
                return String(input[Range(match.range, in: input)!])
            }
        } catch {
            print("Error creating regex: \(error)")
        }
        
        return input
    }
    
    func extractDomain(from url: String) -> String? {
        guard let parsedURL = URL(string: url),
              let host = parsedURL.host else {
            return url
        }

        return host
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let loadedImage:UIImage = UIImage(named: "SAMPLE_4")!

        inputImage = CIImage(image:loadedImage)!
        
        pictureBox.image = UIImage(ciImage: inputImage!)
        
        doOCR(ciImage: inputImage!) { result in
            switch result {
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

}

private extension String {
    var words: Set<String> {
        return Set(components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
    }

    func containsWords(of string: String) -> Bool {
        return words.isSuperset(of: string.words)
    }
}

