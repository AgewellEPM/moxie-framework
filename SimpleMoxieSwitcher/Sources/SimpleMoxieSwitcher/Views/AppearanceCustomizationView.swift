import SwiftUI

struct AppearanceCustomizationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppearanceViewModel

    // Face feature selections
    @State private var selectedEyes = "Purple"
    @State private var selectedFaceColors = "Pink"
    @State private var selectedEyeDesigns = "Default"
    @State private var selectedFaceDesigns = "Default"
    @State private var selectedEyelidDesigns = "Default"
    @State private var selectedMouth = "RedMedium"
    @State private var selectedHeadHair = "Default"
    @State private var selectedFacialHair = "Default"
    @State private var selectedBrows = "Default"
    @State private var selectedGlasses = "BlueHeart"
    @State private var selectedNose = "Default"

    private func instantApply() async {
        await viewModel.applyAppearance(
            eyes: selectedEyes,
            faceColors: selectedFaceColors,
            eyeDesigns: selectedEyeDesigns,
            faceDesigns: selectedFaceDesigns,
            eyelidDesigns: selectedEyelidDesigns,
            mouth: selectedMouth,
            headHair: selectedHeadHair,
            facialHair: selectedFacialHair,
            brows: selectedBrows,
            glasses: selectedGlasses,
            nose: selectedNose
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("💇 Customize Moxie's Look")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // EYES SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        Text("👁️ EYES")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Eyes Color", selection: $selectedEyes) {
                            Text("Default").tag("Default")
                            Text("Brown").tag("Brown")
                            Text("Gold").tag("Gold")
                            Text("Grey").tag("Grey")
                            Text("Hazel").tag("Hazel")
                            Text("Light Blue").tag("LightBlue")
                            Text("Purple").tag("Purple")
                            Text("Turquoise").tag("Turquoise")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedEyes) { _ in
                            Task { await instantApply() }
                        }
                    }

                    // FACE COLORS SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🎨 FACE COLORS")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Face Colors", selection: $selectedFaceColors) {
                            Text("Default").tag("Default")
                            Text("Green").tag("Green")
                            Text("Pink").tag("Pink")
                            Text("Purple").tag("Purple")
                            Text("Teal").tag("Teal")
                            Text("Yellow").tag("Yellow")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.pink.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedFaceColors) { _ in
                            Task { await instantApply() }
                        }
                    }

                    Divider()

                    // HAIR & FACIAL HAIR SECTION
                    Text("💈 HAIR & FACIAL FEATURES")
                        .font(.title3)
                        .bold()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("💇 HEAD HAIR")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Head Hair", selection: $selectedHeadHair) {
                            Text("Default (None)").tag("Default")
                            Text("Black Bob").tag("BlackBob")
                            Text("Black Center").tag("BlackCenter")
                            Text("Pink Shag").tag("PinkShag")
                            Text("Red Shag").tag("RedShag")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.brown.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedHeadHair) { _ in
                            Task { await instantApply() }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("🧔 FACIAL HAIR")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Facial Hair", selection: $selectedFacialHair) {
                            Text("Default (None)").tag("Default")
                            Text("Black Angled").tag("BlackAngled")
                            Text("Black Dali").tag("BlackDali")
                            Text("Brown Handlebar").tag("BrownHandlebar")
                            Text("Orange Bat Wing").tag("OrangeBatWing")
                            Text("Yellow Upturn").tag("YellowUpturn")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.brown.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedFacialHair) { _ in
                            Task { await instantApply() }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("🤨 EYEBROWS")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Brows", selection: $selectedBrows) {
                            Text("Default").tag("Default")
                            Text("Brown Cut").tag("BrownCut")
                            Text("Grey Short").tag("GreyShort")
                            Text("Purple").tag("Purple")
                            Text("White Bushy").tag("WhiteBushy")
                            Text("Yellow Thin").tag("YellowThin")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.brown.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedBrows) { _ in
                            Task { await instantApply() }
                        }
                    }

                    Divider()

                    // ACCESSORIES SECTION
                    Text("👓 ACCESSORIES")
                        .font(.title3)
                        .bold()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("👓 GLASSES")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Glasses", selection: $selectedGlasses) {
                            Text("Default (None)").tag("Default")
                            Text("Blue Heart").tag("BlueHeart")
                            Text("Gold Half Round").tag("GoldHalfRound")
                            Text("Red Cat").tag("RedCat")
                            Text("Round White Dot").tag("RoundWhiteDot")
                            Text("Small Round").tag("SmallRound")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedGlasses) { _ in
                            Task { await instantApply() }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("👃 NOSE")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Nose", selection: $selectedNose) {
                            Text("Default").tag("Default")
                            Text("Cat").tag("Cat")
                            Text("Clown").tag("Clown")
                            Text("Dog").tag("Dog")
                            Text("Human").tag("Human01")
                            Text("Pig").tag("Pig")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedNose) { _ in
                            Task { await instantApply() }
                        }
                    }

                    Divider()

                    // FACE DETAILS SECTION
                    Text("✨ FACE DETAILS")
                        .font(.title3)
                        .bold()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("👄 MOUTH")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Mouth", selection: $selectedMouth) {
                            Text("Default").tag("Default")
                            Text("Black Small").tag("BlackSmall")
                            Text("Dark Red Medium").tag("DarkRedMedium")
                            Text("Pink Pointy").tag("PinkPointy")
                            Text("Purple Full").tag("PurpleFull")
                            Text("Red Medium").tag("RedMedium")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedMouth) { _ in
                            Task { await instantApply() }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("👁️‍🗨️ EYE DESIGNS")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Eye Designs", selection: $selectedEyeDesigns) {
                            Text("Default").tag("Default")
                            Text("Blue Circuits").tag("BlueCircuits")
                            Text("Blue Clouds").tag("BlueClouds")
                            Text("Circuits").tag("Circuits")
                            Text("Clouds").tag("Clouds")
                            Text("Gears").tag("Gears")
                            Text("Gold Stars").tag("GoldStars")
                            Text("Purple Gears").tag("PurpleGears")
                            Text("Red Hearts").tag("RedHearts")
                            Text("Stars").tag("Stars")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.cyan.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedEyeDesigns) { _ in
                            Task { await instantApply() }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("💄 EYELID DESIGNS")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Eyelid Designs", selection: $selectedEyelidDesigns) {
                            Text("Default").tag("Default")
                            Text("Green Eye Shadow").tag("GreenEyeShadow")
                            Text("Purple Eye Shadow").tag("PurpleEyeShadow")
                            Text("Rainbow Stars").tag("RainbowStars")
                            Text("Red Eye Shadow").tag("RedEyeShadow")
                            Text("Smokey Lashes").tag("SmokeyLashes")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedEyelidDesigns) { _ in
                            Task { await instantApply() }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("🌸 FACE DESIGNS")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Picker("Face Designs", selection: $selectedFaceDesigns) {
                            Text("Default").tag("Default")
                            Text("Candies").tag("Candies")
                            Text("Flowers").tag("Flowers01")
                            Text("Hearts").tag("Hearts")
                            Text("Leaves").tag("Leaves01")
                            Text("Stars").tag("Stars")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)
                        .onChange(of: selectedFaceDesigns) { _ in
                            Task { await instantApply() }
                        }
                    }

                    Divider()

                    // Warning
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ CAUTION")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("Aside from Eyes and Face Colors, other custom assets have had little testing and may cause Moxie to be unstable. Use at your own risk!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(20)
            }

            // Apply Button
            Button(action: {
                Task {
                    await viewModel.applyAppearance(
                        eyes: selectedEyes,
                        faceColors: selectedFaceColors,
                        eyeDesigns: selectedEyeDesigns,
                        faceDesigns: selectedFaceDesigns,
                        eyelidDesigns: selectedEyelidDesigns,
                        mouth: selectedMouth,
                        headHair: selectedHeadHair,
                        facialHair: selectedFacialHair,
                        brows: selectedBrows,
                        glasses: selectedGlasses,
                        nose: selectedNose
                    )
                    dismiss()
                }
            }) {
                Text("Apply Customization")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .cornerRadius(10)
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 700)
    }
}