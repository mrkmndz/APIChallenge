//
//  ViewController.swift
//  CODE2040iOS
//
//  Created by Mark Mendoza on 1/6/15.
//  Copyright (c) 2015 Komandez Development. All rights reserved.
//

import UIKit

import Alamofire

class ViewController: UIViewController {
    //outlets to be able to control the images of the checkmarks
    @IBOutlet weak var c1Check: UIImageView!
    @IBOutlet weak var c2Check: UIImageView!
    @IBOutlet weak var c3Check: UIImageView!
    @IBOutlet weak var c4Check: UIImageView!
    
    //runs when view comes up
    override func viewDidLoad() {
        super.viewDidLoad()//superclass needs to be initialized too
        //start the checkmarks hidden
        c1Check.hidden=true
        c2Check.hidden=true
        c3Check.hidden=true
        c4Check.hidden=true
    }
    
    //called by main button
    @IBAction func ButtonPress(sender: AnyObject) {
        //when you push the button, hide the buttons, so retrials also refresh the checkmarks
        c1Check.hidden=true
        c2Check.hidden=true
        c3Check.hidden=true
        c4Check.hidden=true
        //make sure this runs on the main queue, not best practice in general with iOS apps, but makes sure this 
        //test app runs in a reasonable amount of time
        dispatch_async(dispatch_get_main_queue()) {
            //call the first method in the chain
            self.runChallenge()
        }
    }
    
    //utility method to avoid retyping the domain name, basically puts together an array of the used urls
    func url(index: Int) -> String {
        let prefix = "http://challenge.code2040.org/api/"
        let suffixes = ["register","getstring","validatestring","haystack","validateneedle","prefix", "validateprefix", "time", "validatetime","status"]
        return prefix + suffixes[index]
    }
    /*
    This block coming up is the main body of the challenge.
    It goes one by one through the different parts of the challenge, using the Alamofire networking library
    the response handlers do the actual manipulation, those are the anonymous functions accepted by the responsejson method
    because it is async, each response handler, once it is finished, and passes the info back to the server, calls the next method within the request handler to avoid stuff going out of order
    */
    //this method gets the token from the server and passes it onto reverseChallenge
    func runChallenge(){
        //basic syntax of Alamofire: Alamofire.request(method (in our case always post) referring to an enum inside the framework (I think), url as a string, parameters as a dictionary mapping strings to AnyObject(s), encoding of the parameters (in our case always json))
        Alamofire.request(.POST, url(0), parameters:["email":"mendoza.mark.a@gmail.com","github":"https://github.com/mrkmndz/APIChallenge"], encoding: .JSON)
            //responseJSON takes a "response handler" which in our case is always just an anonymous function
            //we don't care about requests, urlresponse or errors so we drop them (_)
            .responseJSON { (_, _, JSON, _) in
                //this takes the token and casts it as a string to string dictionary and then gets the value assosciated with "result" and unwraps it (how Swift deals with optionals)
                let token = (JSON as [String : String])["result"]!
                //calls the next challenge
                self.reverseChallenge(token)
        }
    }
    
    //Challenge 1
    func reverseChallenge(token: String){
        //get the string
        Alamofire.request(.POST, url(1), parameters:["token":token], encoding: .JSON)
                .responseJSON { (_, _, JSON, _) in
                    //extract it
                    let given = (JSON as [String : String])["result"]!
                    //easy way to reverse it
                    let reversed = String(reverse(given))
                    //post it back
                    Alamofire.request(.POST, self.url(2), parameters:["token": token, "string" : reversed], encoding: .JSON)
                        .responseJSON { (_, _, JSON, _) in
                            //once you get a response, call the next challenge
                            self.needleChallenge(token)
                    }
        }
    }
    
    //Challenge 2
    func needleChallenge(token: String){
        //get the needle and haystack
        Alamofire.request(.POST, url(3), parameters:["token":token], encoding: .JSON)
            .responseJSON{ (_, _, JSON, _) in
                //extract the response
                let given = (JSON as [String : [String:AnyObject]])["result"]!
                //extract the haystack
                let haystack = given["haystack"] as [String]
                //extract the needle
                let needle = given["needle"] as String
                //easy boring way
                //let index = Int(find(haystack, needle)!)
                //Swift has so many built in collection manipulation techniques
                //the hard(er) way
                var n=0//make a counter
                var index = Int()//make an output
                //for each member of the haystack array
                for hay in haystack {
                    //check if its the needle
                    if hay == needle {
                        //if it is then set the return value
                        index = n
                        break
                    }
                    //if not just increment the counter
                    n++
                }
                //pass back the answer
                Alamofire.request(.POST, self.url(4), parameters:["token": token, "needle" : index], encoding: .JSON)
                    .responseJSON { (_, _, JSON, _) in
                        //call the next challenge
                        self.prefixChallenge(token)
                }
        }
    }
    
    //challenge 3
    func prefixChallenge(token: String){
        //get the array and prefix
        Alamofire.request(.POST, url(5), parameters:["token":token], encoding: .JSON)
            .responseJSON{ (_, _, JSON, _) in
                //unpack everything
                let given = (JSON as [String : [String:AnyObject]])["result"]!
                let givenArray = given["array"] as [String]
                let prefix =  given["prefix"] as String
                //set up an empty array for the filtered answers
                var filteredArray: [String] = []
                //for each member in the array
                for word in givenArray {
                    //start off assuming its a match
                    var match = true
                    //start a counter at 0
                    var n = 0
                    //for each character in the string prefix (IN ORDER)
                    for char in prefix{
                        //check if the corresponding character in the candidate string matches
                        if Array(word)[n] != char{
                            //if it doesn't, set match to false
                            match = false
                            break
                        }
                        //otherwise, increment the counter
                        n++
                    }
                    //now if that didn't yield a match
                    if !match{
                        //add it to the filtered list
                        filteredArray.append(word)
                    }
                }
                //post it up
                Alamofire.request(.POST, self.url(6), parameters:["token": token, "array" : filteredArray], encoding: .JSON)
                    .responseJSON { (_, _, JSON, _) in
                        //move on to the next one
                        self.datingChallenge(token)
                }
        }
    }
    //challenge 4
    func datingChallenge(token: String){
        //get the info
        Alamofire.request(.POST, url(7), parameters:["token":token], encoding: .JSON)
            .responseJSON{ (_, _, JSON, _) in
                //unpack it
                let given = (JSON as [String : [String:AnyObject]])["result"]!
                let datestamp = given["datestamp"] as String
                let interval = given["interval"] as Int
                //make a formatter object
                let dateStringFormatter = NSDateFormatter()
                //establish its format as being ISO
                dateStringFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
                //turn the string into a date
                let olddate = dateStringFormatter.dateFromString(datestamp)
                //turn the date into a new date using the old date and the interval
                let newdate = NSDate(timeInterval:NSTimeInterval(interval), sinceDate:olddate!)
                //turn the new date into a string
                let output = dateStringFormatter.stringFromDate(newdate)
                //post it off
                Alamofire.request(.POST, self.url(8), parameters:["token": token, "datestamp" : output], encoding: .JSON)
                    .responseJSON { (_, _, JSON, _) in
                        //go to the final step
                        self.getScore(token)
                }
        }
    }
    func getScore(token: String){
        //get the pass fail status
        Alamofire.request(.POST, url(9), parameters:["token":token], encoding: .JSON)
            .responseJSON{ (_, _, JSON, _) in
                //unpack
                let results = (JSON as [String : [String:Bool]])["result"]!
                //if its not a nil value (unlisted)
                if (results["Stage 1 passed"] != nil) {
                    //then pass fail determines the state of the checks
                    self.c1Check.hidden = !results["Stage 1 passed"]!
                }
                //etc...
                if (results["Stage 2 passed"] != nil) {
                    self.c2Check.hidden = !results["Stage 2 passed"]!
                }
                if (results["Stage 3 passed"] != nil) {
                    self.c3Check.hidden = !results["Stage 3 passed"]!
                }
                if (results["Stage 4 passed"] != nil) {
                    self.c4Check.hidden = !results["Stage 4 passed"]!
                }

        }
    }
}

