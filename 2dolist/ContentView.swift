
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var Setting = false
    @Query var Tasks : [Task]
    @State var weather : String = ""
    let notificationManager = NotificationManager()
    var body: some View {
        NavigationView {
            
            ZStack {
                Color.white
                VStack(spacing: 20) {
                    Spacer()
                    VStack{
                        Text("Today's Forecast")
                            .font(.system(size: 30, weight: .light, design: .serif))
                            .foregroundColor(.black)
                        Text(weather)
                            .font(.system(size: 70, weight: .semibold, design: .monospaced))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    ZStack{
                        NavigationLink(destination: TaskListView()) {
                            Text("START")
                                .frame(width: 90, height: 90) // Set a fixed size for the circular button
                                .font(.system(size: 27, weight: .medium))
                                .fontDesign(.monospaced)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.black)
                                .clipShape(Circle()) // Use clipShape to make the button circular
                        }
                        .environment(\.colorScheme, .light)
                    }
                    Spacer()
                    
                }
                .padding()
            }
            .navigationBarTitle("2DoList")
            
        }
        .onAppear{
            forecast()
            notificationManager.AskPermission()
        }
        
    }
    private func forecast(){
        if Tasks.isEmpty{
            weather = "Clear"
        }
        else if Tasks.count > 7 {
            weather = "Stormy"
        }
        else{
            weather = "Cloudy"
        }
    }
}

#Preview {
    ContentView()
}




