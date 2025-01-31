import GoogleSignIn
import UIKit

class ViewController: UIViewController {
    private var accessToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // check if user is already logged in
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
                // user is already logged in, we can retrieve token and make api call
                self.accessToken = user.accessToken.tokenString
                self.makeDeviceQueryCall()
            }
            else{
                //user not logged in, we need to present sign in screen
            }
        }
    }

    @IBAction func signInButtonTapped(_ sender: UIButton) {
        guard let clientID = FirebaseApp.app()?.options.clientID else{
            print("invalid client id")
            return
        }
        let signInConfig = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { signInResult, error in
            guard let result = signInResult, error == nil else {
                print("Error signing in: \(error?.localizedDescription ?? "unknown")")
                return
            }

            self.accessToken = result.user.accessToken.tokenString
            print("Successfully signed in, access token: \(self.accessToken ?? "no access token")")
            self.makeDeviceQueryCall()
            }
    }

    //makeDeviceQueryCall function
    func makeDeviceQueryCall(){
       guard let accessToken = accessToken else{
           print("no access token found, can not make device query call")
           return
        }
         
        guard let url = URL(string: "https://homegraph.googleapis.com/v1/devices:query") else{
             print("invalid url")
            return
        }
         
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let requestBody = try? JSONEncoder().encode(["devices": []])
        request.httpBody = requestBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making API request: \(error.localizedDescription)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode) else {
                    if let response = response as? HTTPURLResponse{
                        print("invalid response: \(response.statusCode)")
                    }
                    print("Invalid response")
                    return
                }

                guard let data = data else {
                    print("No data returned from API")
                    return
                }
                
                do{
                     let jsonString = String(data: data, encoding: .utf8)
                     print(jsonString)
                     // parse the data
                    if let devices = parseDeviceQueryResponse(data: data){
                        for device in devices {
                            print("device: \(device)")
                            let capabilities = extractCapabilities(device: device)
                            print("device capabilities: \(capabilities)")
                        }
                    }

                }
            }

        task.resume()
    }
}
