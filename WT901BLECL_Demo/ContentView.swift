//
//  ContentView.swift
//  WT901BLECL_Demo
//
//  Created by transistorgit on 26.11.20.
//

import SwiftUI
import CoreData
import CoreBluetooth

struct vessel_port: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height

            path.addLines( [
                CGPoint(x: width * 0.2, y: height * 0.5),
                CGPoint(x: width * 0.3, y: height * 0.5),
                CGPoint(x: width * 0.3, y: height * 0.4),
                CGPoint(x: width * 0.32, y: height * 0.4),
                CGPoint(x: width * 0.32, y: height * 0.5),
                CGPoint(x: width * 0.6, y: height * 0.5),
                CGPoint(x: width * 0.6, y: height * 0.4),
                CGPoint(x: width * 0.7, y: height * 0.4),
                CGPoint(x: width * 0.7, y: height * 0.5),
                CGPoint(x: width * 0.72, y: height * 0.5),
                CGPoint(x: width * 0.72, y: height * 0.6),
                CGPoint(x: width * 0.3, y: height * 0.6),
            ])
            path.closeSubpath()
        }
    }
}

struct vessel_stern: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height

            path.addLines( [
                CGPoint(x: width * 0.4, y: height * 0.5),
                CGPoint(x: width * 0.45, y: height * 0.5),
                CGPoint(x: width * 0.45, y: height * 0.44),
                CGPoint(x: width * 0.42, y: height * 0.44),
                CGPoint(x: width * 0.42, y: height * 0.4),
                CGPoint(x: width * 0.60, y: height * 0.4),
                CGPoint(x: width * 0.60, y: height * 0.44),
                CGPoint(x: width * 0.57, y: height * 0.44),
                CGPoint(x: width * 0.57, y: height * 0.44),
                CGPoint(x: width * 0.57, y: height * 0.5),
                CGPoint(x: width * 0.62, y: height * 0.5),
                CGPoint(x: width * 0.62, y: height * 0.6),
                CGPoint(x: width * 0.58, y: height * 0.63),
                CGPoint(x: width * 0.45, y: height * 0.63),
                CGPoint(x: width * 0.4, y: height * 0.6),
                CGPoint(x: width * 0.4, y: height * 0.5),
            ])
            path.closeSubpath()
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var bleConnection = BLEConnection()
    @State var calibInProgress = false

    var body: some View {
        VStack{
            Text("WT901BLE IMU Data").font(.title).padding(.bottom, 20.0).onAppear(perform: connectBLEDevice)

            Text(verbatim: bleConnection.imuData ?? "waiting for data").font(.title2).padding(.bottom, 10.0)

            HStack{
                Text("Pitch").font(.title2)
                vessel_port()
                    .stroke(lineWidth:3)
                    .frame(width: 250, height: 250, alignment: .center)
                    .rotationEffect(Angle(degrees: bleConnection.imuPitch ?? 0.0))
                Text(String(format: "%.f°", bleConnection.imuPitch ?? 0.0)).font(.title2)
            }
            HStack{
                Text("Roll").font(.title2)
                vessel_stern()
                    .stroke(lineWidth:3)
                    .frame(width: 250, height: 250, alignment: .center)
                    .rotationEffect(Angle(degrees: bleConnection.imuRoll ?? 0.0))
                Text(String(format: "%.f°", bleConnection.imuRoll ?? 0.0)).font(.title2)
            }

            HStack{
                Button(action: { self.bleConnection.setUpdateRate(frequency: 10)}) {
                    Text("10Hz").font(.largeTitle).padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/).frame(width: /*@START_MENU_TOKEN@*/120.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/).cornerRadius(/*@START_MENU_TOKEN@*/12.0/*@END_MENU_TOKEN@*/).background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.gray/*@END_MENU_TOKEN@*/).clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                }
                Button(action: { self.bleConnection.setUpdateRate(frequency: 1)}) {
                    Text("1Hz").font(.largeTitle).padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/).frame(width: /*@START_MENU_TOKEN@*/120.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/).cornerRadius(/*@START_MENU_TOKEN@*/12.0/*@END_MENU_TOKEN@*/).background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.gray/*@END_MENU_TOKEN@*/).clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                }
                Button(action: { doCalib() }){
                    Text("Calib").font(.largeTitle).padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/).frame(width: /*@START_MENU_TOKEN@*/120.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/).cornerRadius(/*@START_MENU_TOKEN@*/12.0/*@END_MENU_TOKEN@*/).background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.gray/*@END_MENU_TOKEN@*/).clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                }
            }
            .padding()
        }.padding()
        .alert(isPresented: $bleConnection.showAlert, content: {
            Alert(title: Text("Error"), message: Text("Connection Lost"))
        })
    }

    private func doCalib(){
        if !calibInProgress {
            self.bleConnection.calibrate();
            calibInProgress = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                calibInProgress = false
                bleConnection.saveCurrentConfig()
            }
        }
    }

    private func connectBLEDevice(){
        bleConnection.startCentralManager()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
