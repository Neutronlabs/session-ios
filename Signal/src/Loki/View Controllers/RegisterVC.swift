import Sodium

final class RegisterVC : BaseVC {
    private var seed: Data! { didSet { updateKeyPair() } }
    private var ed25519KeyPair: Sign.KeyPair!
    private var x25519KeyPair: ECKeyPair! { didSet { updatePublicKeyLabel() } }
    
    // MARK: Components
    private lazy var publicKeyLabel: UILabel = {
        let result = UILabel()
        result.textColor = Colors.text
        result.font = Fonts.spaceMono(ofSize: isIPhone5OrSmaller ? Values.mediumFontSize : 20)
        result.numberOfLines = 0
        result.lineBreakMode = .byCharWrapping
        return result
    }()
    
    private lazy var copyPublicKeyButton: Button = {
        let result = Button(style: .prominentOutline, size: .large)
        result.setTitle(NSLocalizedString("copy", comment: ""), for: UIControl.State.normal)
        result.titleLabel!.font = .boldSystemFont(ofSize: Values.mediumFontSize)
        result.addTarget(self, action: #selector(copyPublicKey), for: UIControl.Event.touchUpInside)
        return result
    }()
    
    private lazy var legalLabel: UILabel = {
        let result = UILabel()
        result.textColor = Colors.text
        result.font = .systemFont(ofSize: Values.verySmallFontSize)
        let text = "By using this service, you agree to our Terms of Service, End User License Agreement (EULA) and Privacy Policy"
        let attributedText = NSMutableAttributedString(string: text, attributes: [ .font : UIFont.systemFont(ofSize: Values.verySmallFontSize) ])
        attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: Values.verySmallFontSize), range: (text as NSString).range(of: "Terms of Service"))
        attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: Values.verySmallFontSize), range: (text as NSString).range(of: "End User License Agreement (EULA)"))
        attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: Values.verySmallFontSize), range: (text as NSString).range(of: "Privacy Policy"))
        result.attributedText = attributedText
        result.numberOfLines = 0
        result.textAlignment = .center
        result.lineBreakMode = .byWordWrapping
        return result
    }()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGradientBackground()
        setUpNavBarStyle()
        setUpNavBarSessionIcon()
        // Set up title label
        let titleLabel = UILabel()
        titleLabel.textColor = Colors.text
        titleLabel.font = .boldSystemFont(ofSize: isIPhone5OrSmaller ? Values.largeFontSize : Values.veryLargeFontSize)
        titleLabel.text = NSLocalizedString("vc_register_title", comment: "")
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        // Set up explanation label
        let explanationLabel = UILabel()
        explanationLabel.textColor = Colors.text
        explanationLabel.font = .systemFont(ofSize: Values.smallFontSize)
        explanationLabel.text = NSLocalizedString("vc_register_explanation", comment: "")
        explanationLabel.numberOfLines = 0
        explanationLabel.lineBreakMode = .byWordWrapping
        // Set up public key label container
        let publicKeyLabelContainer = UIView()
        publicKeyLabelContainer.addSubview(publicKeyLabel)
        publicKeyLabel.pin(to: publicKeyLabelContainer, withInset: Values.mediumSpacing)
        publicKeyLabelContainer.layer.cornerRadius = Values.textFieldCornerRadius
        publicKeyLabelContainer.layer.borderWidth = Values.borderThickness
        publicKeyLabelContainer.layer.borderColor = Colors.text.cgColor
        // Set up spacers
        let topSpacer = UIView.vStretchingSpacer()
        let bottomSpacer = UIView.vStretchingSpacer()
        // Set up register button
        let registerButton = Button(style: .prominentFilled, size: .large)
        registerButton.setTitle(NSLocalizedString("continue_2", comment: ""), for: UIControl.State.normal)
        registerButton.titleLabel!.font = .boldSystemFont(ofSize: Values.mediumFontSize)
        registerButton.addTarget(self, action: #selector(register), for: UIControl.Event.touchUpInside)
        // Set up button stack view
        let buttonStackView = UIStackView(arrangedSubviews: [ registerButton, copyPublicKeyButton ])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = isIPhone5OrSmaller ? Values.smallSpacing : Values.mediumSpacing
        buttonStackView.alignment = .fill
        // Set up button stack view container
        let buttonStackViewContainer = UIView()
        buttonStackViewContainer.addSubview(buttonStackView)
        buttonStackView.pin(.leading, to: .leading, of: buttonStackViewContainer, withInset: Values.massiveSpacing)
        buttonStackView.pin(.top, to: .top, of: buttonStackViewContainer)
        buttonStackViewContainer.pin(.trailing, to: .trailing, of: buttonStackView, withInset: Values.massiveSpacing)
        buttonStackViewContainer.pin(.bottom, to: .bottom, of: buttonStackView)
        // Set up legal label
        legalLabel.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleLegalLabelTapped))
        legalLabel.addGestureRecognizer(tapGestureRecognizer)
        // Set up legal label container
        let legalLabelContainer = UIView()
        legalLabelContainer.set(.height, to: Values.onboardingButtonBottomOffset)
        legalLabelContainer.addSubview(legalLabel)
        legalLabel.pin(.leading, to: .leading, of: legalLabelContainer, withInset: Values.massiveSpacing)
        legalLabel.pin(.top, to: .top, of: legalLabelContainer)
        legalLabelContainer.pin(.trailing, to: .trailing, of: legalLabel, withInset: Values.massiveSpacing)
        legalLabelContainer.pin(.bottom, to: .bottom, of: legalLabel, withInset: isIPhone5OrSmaller ? 6 : 10)
        // Set up top stack view
        let topStackView = UIStackView(arrangedSubviews: [ titleLabel, explanationLabel, publicKeyLabelContainer ])
        topStackView.axis = .vertical
        topStackView.spacing = isIPhone5OrSmaller ? Values.smallSpacing : Values.veryLargeSpacing
        topStackView.alignment = .fill
        // Set up top stack view container
        let topStackViewContainer = UIView()
        topStackViewContainer.addSubview(topStackView)
        topStackView.pin(.leading, to: .leading, of: topStackViewContainer, withInset: Values.veryLargeSpacing)
        topStackView.pin(.top, to: .top, of: topStackViewContainer)
        topStackViewContainer.pin(.trailing, to: .trailing, of: topStackView, withInset: Values.veryLargeSpacing)
        topStackViewContainer.pin(.bottom, to: .bottom, of: topStackView)
        // Set up main stack view
        let mainStackView = UIStackView(arrangedSubviews: [ topSpacer, topStackViewContainer, bottomSpacer, buttonStackViewContainer, legalLabelContainer ])
        mainStackView.axis = .vertical
        mainStackView.alignment = .fill
        view.addSubview(mainStackView)
        mainStackView.pin(to: view)
        topSpacer.heightAnchor.constraint(equalTo: bottomSpacer.heightAnchor, multiplier: 1).isActive = true
        // Peform initial seed update
        updateSeed()
    }
    
    // MARK: General
    @objc private func enableCopyButton() {
        copyPublicKeyButton.isUserInteractionEnabled = true
        UIView.transition(with: copyPublicKeyButton, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.copyPublicKeyButton.setTitle(NSLocalizedString("copy", comment: ""), for: UIControl.State.normal)
        }, completion: nil)
    }
    
    // MARK: Updating
    private func updateSeed() {
        seed = Data.getSecureRandomData(ofSize: 16)!
    }
    
    private func updateKeyPair() {
        let padding = Data(repeating: 0, count: 16)
        ed25519KeyPair = Sodium().sign.keyPair(seed: (seed + padding).bytes)!
        let x25519PublicKey = Sodium().sign.toX25519(ed25519PublicKey: ed25519KeyPair.publicKey)!
        let x25519SecretKey = Sodium().sign.toX25519(ed25519SecretKey: ed25519KeyPair.secretKey)!
        x25519KeyPair = ECKeyPair(publicKey: Data(x25519PublicKey), privateKey: Data(x25519SecretKey))
    }
    
    private func updatePublicKeyLabel() {
        let hexEncodedPublicKey = x25519KeyPair.hexEncodedPublicKey
        let characterCount = hexEncodedPublicKey.count
        var count = 0
        let limit = 32
        func animate() {
            let numberOfIndexesToShuffle = 32 - count
            let indexesToShuffle = (0..<characterCount).shuffled()[0..<numberOfIndexesToShuffle]
            var mangledHexEncodedPublicKey = hexEncodedPublicKey
            for index in indexesToShuffle {
                let startIndex = mangledHexEncodedPublicKey.index(mangledHexEncodedPublicKey.startIndex, offsetBy: index)
                let endIndex = mangledHexEncodedPublicKey.index(after: startIndex)
                mangledHexEncodedPublicKey.replaceSubrange(startIndex..<endIndex, with: "0123456789abcdef__".shuffled()[0..<1])
            }
            count += 1
            if count < limit {
                publicKeyLabel.text = mangledHexEncodedPublicKey
                Timer.scheduledTimer(withTimeInterval: 0.032, repeats: false) { _ in
                    animate()
                }
            } else {
                publicKeyLabel.text = hexEncodedPublicKey
            }
        }
        animate()
    }
    
    // MARK: Interaction
    @objc private func register() {
        let dbConnection = OWSIdentityManager.shared().dbConnection
        let collection = OWSPrimaryStorageIdentityKeyStoreCollection
        dbConnection.setObject(seed.toHexString(), forKey: LKSeedKey, inCollection: collection)
        dbConnection.setObject(ed25519KeyPair.secretKey.toHexString(), forKey: LKED25519SecretKey, inCollection: collection)
        dbConnection.setObject(ed25519KeyPair.publicKey.toHexString(), forKey: LKED25519PublicKey, inCollection: collection)
        dbConnection.setObject(x25519KeyPair!, forKey: OWSPrimaryStorageIdentityKeyStoreIdentityKey, inCollection: collection)
        TSAccountManager.sharedInstance().phoneNumberAwaitingVerification = x25519KeyPair!.hexEncodedPublicKey
        OWSPrimaryStorage.shared().setRestorationTime(0)
        UserDefaults.standard[.hasViewedSeed] = false
        let displayNameVC = DisplayNameVC()
        navigationController!.pushViewController(displayNameVC, animated: true)
    }
    
    @objc private func copyPublicKey() {
        UIPasteboard.general.string = x25519KeyPair.hexEncodedPublicKey
        copyPublicKeyButton.isUserInteractionEnabled = false
        UIView.transition(with: copyPublicKeyButton, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.copyPublicKeyButton.setTitle("Copied", for: UIControl.State.normal)
        }, completion: nil)
        Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(enableCopyButton), userInfo: nil, repeats: false)
    }
    
    @objc private func handleLegalLabelTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        let urlAsString: String?
        let tosRange = (legalLabel.text! as NSString).range(of: "Terms of Service")
        let eulaRange = (legalLabel.text! as NSString).range(of: "End User License Agreement (EULA)")
        let ppRange = (legalLabel.text! as NSString).range(of: "Privacy Policy")
        let touchInLegalLabelCoordinates = tapGestureRecognizer.location(in: legalLabel)
        let characterIndex = legalLabel.characterIndex(for: touchInLegalLabelCoordinates)
        if tosRange.contains(characterIndex) {
            urlAsString = "https://getsession.org/terms-of-service/"
        } else if eulaRange.contains(characterIndex) {
            urlAsString = "https://getsession.org/terms-of-service/#eula"
        } else if ppRange.contains(characterIndex) {
            urlAsString = "https://getsession.org/privacy-policy/"
        } else {
            urlAsString = nil
        }
        if let urlAsString = urlAsString {
            let url = URL(string: urlAsString)!
            UIApplication.shared.open(url)
        }
    }
}
