import SwiftUI
import MapKit

struct LocationProposalConfirmView: View {
    let location: MapSearchResult
    let meetingTime: String?
    let contactData: ContactData
    @Binding var isPresented: Bool
    var onConfirm: (String?) -> Void
    
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var additionalMessage: String = ""
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Dim background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(localizationManager.localize("CONFIRM_LOCATION_PROPOSAL"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
                .background(Color.white)
                .border(Color(hex: "e2e8f0"), width: 1)
                
                // Content - Scrollable with max height
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                    // Map preview
                    ZStack(alignment: .topTrailing) {
                        Map(position: $cameraPosition) {
                            Annotation("", coordinate: location.coordinate) {
                                VStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.red)
                                    Text(location.name)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .mapStyle(.standard)
                        .cornerRadius(8)
                        .frame(height: 200)
                    }
                    .onAppear {
                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        cameraPosition = .region(MKCoordinateRegion(center: location.coordinate, span: span))
                    }
                    
                    // Location details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localize("PROPOSED_LOCATION"))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Text(location.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        if !location.address.isEmpty {
                            Text(location.address)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(12)
                    .background(Color(hex: "f7fafc"))
                    .cornerRadius(8)
                    
                    // Meeting time (if available)
                    if let meetingTime = meetingTime {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MEETING_TIME")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            Text(DateFormatters.formatCompact(meetingTime))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "2d3748"))
                        }
                        .padding(12)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                    }
                    
                    // Additional message
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localize("OPTIONAL_MESSAGE"))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        TextField("Add a message...", text: $additionalMessage)
                            .padding(10)
                            .background(Color(hex: "f7fafc"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "cbd5e0"), lineWidth: 1))
                    }
                    }
                    .padding(16)
                }
                .frame(maxHeight: 400)
                .background(Color.white)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { isPresented = false }) {
                        Text(localizationManager.localize("CANCEL"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .foregroundColor(Color(hex: "667eea"))
                            .background(Color(hex: "f0f4ff"))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        isSubmitting = true
                        onConfirm(additionalMessage.isEmpty ? nil : additionalMessage)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isSubmitting = false
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            Text(localizationManager.localize("SEND_PROPOSAL"))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                    }
                    .disabled(isSubmitting)
                }
                .padding(16)
                .background(Color.white)
                .border(Color(hex: "e2e8f0"), width: 1)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(16)
            .frame(maxWidth: 500)
        }
    }
}

#Preview {
    Text("LocationProposalConfirmView Preview")
}
