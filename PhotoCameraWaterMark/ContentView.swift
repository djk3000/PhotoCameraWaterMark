//
//  ContentView.swift
//  PhotoCameraWaterMark
//
//  Created by 邓璟琨 on 2023/12/19.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject var control: PhotoControl = PhotoControl()
    @State private var selectedPhotosPickerItem: PhotosPickerItem?
    @State var image: UIImage?
    @State private var enabled = false
    
    var body: some View {
        ZStack{
            Color.black
                .ignoresSafeArea()
            VStack {
                PhotosPicker(selection: $selectedPhotosPickerItem, matching: .any(of: [.images]), photoLibrary: .shared()) {
                    Text("选择图片")
                }
                .disabled(!enabled)
                .onChange(of: selectedPhotosPickerItem) { newItem in
                    control.resetData()
                    if let newItem = newItem, let localID = newItem.itemIdentifier {
                        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
                        if let asset = result.firstObject {
                            print("Got " + asset.debugDescription)
                            control.getPhotoInfo(photoAsset: asset)
                        }
                        
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                DispatchQueue.main.async {
                                    control.image =  UIImage(data: data)
                                    control.isAdded = false
                                    //                                var data = control.image?.getExifData()
                                    //                                if let dict = data as? [String: AnyObject] {
                                    //                                    print(dict["key"])
                                    //                                }
                                }
                            }
                        }
                    }
                }
                
                
                if control.image != nil {
                    Image(uiImage: control.image ?? UIImage())
                        .resizable()
                        .scaledToFit()
                }
                
                HStack {
                    Button {
                        if control.image != nil {
                            if(control.cameraInfo.isEmpty) { return }
                            control.setPhotoWaterMark(originalImage: control.image!)
                        }
                    } label: {
                        Text("添加水印")
                    }
                    .padding()
                    
                    Button {
                        if control.image != nil {
                            DispatchQueue.main.async {
                                if control.image != nil {
                                    control.saveToPhotosAlbum(image: control.image!)
                                }
                            }
                        }
                    } label: {
                        Text("保存到相册")
                    }
                    .padding()
                }
                .padding()
                
                if control.image != nil {
                    VStack {
                        Text("手机型号: \(control.cameraInfo)")
                        Text("焦距: \(control.focalLength)")
                        Text("光圈: \(control.fNumber)")
                        Text("快门速度: \(control.exposureTime)")
                        Text("ISO: \(control.iso)")
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
            .onAppear {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    enabled = status == .authorized
                }
            }
            .alert("保存成功",isPresented: $control.isSaveSuccess) {
                Button("确定") {
                    control.isSaveSuccess = false
                }
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
