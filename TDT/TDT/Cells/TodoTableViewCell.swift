//
//  TodoTableViewCell.swift
//  TDT
//
//  Created by Yunjae Kim on 2021/01/22.
//

import UIKit
import Then
import SnapKit
import AudioToolbox
import Combine

class TodoTableViewCell: UITableViewCell {
    static let identifier = "TodoTableViewCell"

    @IBOutlet weak var containView: UIView!
    @IBOutlet weak var gradientView: GradientView!

    @IBOutlet weak var todoLabel: UILabel!

    var isImportant = false
    weak var textBoxDelegate: TextBoxDelegate?

    @Published var todoData: TodoData?

    /// 일괄 선택 모드 — 스와이프/더블탭 대신 탭으로 선택을 토글한다
    var isSelectionMode = false {
        didSet {
            updateSelectionAppearance()
            updateGestureEnabling()
        }
    }
    var isChecked = false {
        didSet { updateSelectionAppearance() }
    }

    private let pinImageView = UIImageView()
    private let checkImageView = UIImageView()
    private var isCompleting = false

    private var cancellables = Set<AnyCancellable>()

    private var feedbackGenerator: UIImpactFeedbackGenerator?

    private var doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
    private var singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
    private var leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped))
    // 선택 모드 전용 — 행 전체가 탭 영역이고, 더블탭 대기 없이 즉시 반응한다
    private var selectionTap = UITapGestureRecognizer(target: self, action: #selector(selectionTapped))

    private var mainColor: UIColor {
        guard let currentTheme = ThemeManager.shared.currentTheme else { return Theme.flickBlue.mainColor }
        return currentTheme.mainColor
    }

    var wasSingleTapped = false {
        didSet {
            highlightBoxWhenSingleTappedIfNeeded()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setupUIs()
        subscribeAttributes()
        prepareFeedbackGenerator()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        gradientView.setGradient(color1: mainColor, color2: Design.backgroundColor!)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    override func prepareForReuse() {
        wasSingleTapped = false
        isSelectionMode = false
        isChecked = false
        isCompleting = false
        resetSwipeTransforms()

        setupUIs()
        subscribeAttributes()

        prepareFeedbackGenerator()
        layoutIfNeeded()
    }

    private func subscribeAttributes() {
        for cancellable in cancellables {
            cancellable.cancel()
        }

        $todoData.sink(receiveValue: { [weak self] todoData in
            guard
                let self,
                let todoData
            else { return }

            if todoData.isImportant {
                self.containView.setBorder(borderColor: self.mainColor, borderWidth: 1.5)
            }
            else {
                self.containView.setBorder(borderColor: self.mainColor, borderWidth: 0.0)
            }

            self.pinImageView.isHidden = !todoData.isPinned
            self.setLabel(text: todoData.todo)
        })
        .store(in: &cancellables)
    }

    private func setupUIs(){
        backgroundColor = Design.backgroundColor

        gradientView.alpha = 0

        containView.backgroundColor = Design.boxColor
        containView.makeRounded(cornerRadius: 8)
        containView.alpha = 1
        containView.isUserInteractionEnabled = true

        doubletap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))

        leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwiped))

        leftSwipe.direction = .left

        singleTap.numberOfTapsRequired = 1
        doubletap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubletap)
        containView.addGestureRecognizer(doubletap)
        containView.addGestureRecognizer(singleTap)
        addGestureRecognizer(leftSwipe)

        selectionTap = UITapGestureRecognizer(target: self, action: #selector(selectionTapped))
        contentView.addGestureRecognizer(selectionTap)

        setupPinImageView()
        setupCheckImageView()
        updateGestureEnabling()
    }

    // 선택 모드: 더블탭/단일탭(더블탭 대기 있음)을 끄고 행 전체 즉시 탭으로 전환
    private func updateGestureEnabling() {
        doubletap.isEnabled = !isSelectionMode
        singleTap.isEnabled = !isSelectionMode
        selectionTap.isEnabled = isSelectionMode
    }

    @objc private func selectionTapped() {
        textBoxDelegate?.longTapped(cell: self)
    }

    private func setupPinImageView() {
        pinImageView.image = Design.pinImage
        pinImageView.tintColor = mainColor
        pinImageView.contentMode = .scaleAspectFit
        pinImageView.transform = CGAffineTransform(rotationAngle: .pi / 4)
        pinImageView.isHidden = true

        if pinImageView.superview == nil {
            contentView.addSubview(pinImageView)
        }
        pinImageView.snp.remakeConstraints {
            $0.centerY.equalTo(containView.snp.top).offset(2)
            $0.centerX.equalTo(containView.snp.trailing).offset(-10)
            $0.width.height.equalTo(14)
        }
    }

    private func setupCheckImageView() {
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.isHidden = true

        if checkImageView.superview == nil {
            contentView.addSubview(checkImageView)
        }
        checkImageView.snp.remakeConstraints {
            $0.centerY.equalTo(containView.snp.centerY)
            $0.trailing.equalToSuperview().offset(-20)
            $0.width.height.equalTo(24)
        }
    }

    private func updateSelectionAppearance() {
        checkImageView.isHidden = !isSelectionMode
        checkImageView.image = isChecked ? Design.checkedImage : Design.uncheckedImage
        checkImageView.tintColor = isChecked ? mainColor : Design.inactiveColor
        containView.alpha = isSelectionMode && !isChecked ? 0.55 : 1
    }

    private func prepareFeedbackGenerator() {
        feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator?.prepare()
    }

    @objc func doubleTapped(){
        guard !isSelectionMode else { return }
        feedbackGenerator?.impactOccurred()

        textBoxDelegate?.doubleTapped(cell: self)
    }

    @objc func leftSwiped(){
        guard !isSelectionMode, !isCompleting else { return }
        isCompleting = true

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: { [weak self] in
            guard let self else { return }

            let slide = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
            self.gradientView.alpha = 1
            self.containView.transform = slide
            self.todoLabel.transform = slide
            self.gradientView.transform = slide
        }, completion: { [weak self] _ in
            guard let self else { return }

            // 애니메이션 완료 시점에 델리게이트가 indexPath(for:)로 실제 위치를 조회한다
            self.textBoxDelegate?.leftSwiped(cell: self)
            self.isCompleting = false

            // 삭제 애니메이션이 끝난 뒤 재사용 대비 원복
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.resetSwipeTransforms()
            }
        })
    }

    private func resetSwipeTransforms() {
        containView.transform = .identity
        todoLabel.transform = .identity
        gradientView.transform = .identity
        gradientView.alpha = 0
    }

    @objc func singleTapped(){
        if !wasSingleTapped{
            wasSingleTapped = true
            textBoxDelegate?.longTapped(cell: self)
        }
    }

    private func setLabel(text: String){
        todoLabel.text = text
        todoLabel.font = Design.font
        todoLabel.lineBreakMode = .byCharWrapping

        todoLabel.setSpacing(spacing: 5, kernValue: -1)
        todoLabel.textColor = Design.textColor

        containView.snp.remakeConstraints{
            $0.leading.equalTo(todoLabel.snp.leading).offset(-18)
            $0.top.equalTo(todoLabel.snp.top).offset(-15)
            $0.bottom.equalTo(todoLabel.snp.bottom).offset(15)
            $0.trailing.equalTo(todoLabel.snp.trailing).offset(18)
        }

        gradientView.snp.remakeConstraints {
            $0.leading.equalTo(containView.snp.trailing).offset(-18)
            $0.top.equalTo(containView.snp.top)
            $0.bottom.equalTo(containView.snp.bottom)
            $0.width.equalTo(75)
        }
    }

    private func highlightBoxWhenSingleTappedIfNeeded() {
        containView.backgroundColor = wasSingleTapped ? Design.tappedColor : Design.boxColor
    }
}

extension TodoTableViewCell {
    enum Design {
        static let backgroundColor = UIColor(named: "bgColor")
        static let boxColor = UIColor(named: "boxColor")

        static let font = UIFont(name: "GmarketSansTTFMedium", size: 15)?.withFigmaFontSize(500)
        static let textColor = UIColor(named: "mainText")

        static let tappedColor = UIColor(named: "archiveBoxColor")

        static let pinImage = UIImage(systemName: "pin.fill")
        static let checkedImage = UIImage(systemName: "checkmark.circle.fill")
        static let uncheckedImage = UIImage(systemName: "circle")
        static let inactiveColor = UIColor(named: "inactive")
    }
}
