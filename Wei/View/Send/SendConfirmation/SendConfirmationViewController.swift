//
//  SendConfirmationViewController.swift
//  Wei
//
//  Created by omatty198 on 2018/04/02.
//  Copyright © 2018年 popshoot All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Crashlytics

final class SendConfirmationViewController: UIViewController {

    var viewModel: SendConfirmationViewModel!

    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var fiatAmountLabel: UILabel!
    @IBOutlet private weak var etherAmountLabel: UILabel!
    @IBOutlet private weak var fiatFeeLabel: UILabel!
    @IBOutlet private weak var comfirmButton: UIButton!
    @IBOutlet private weak var reselectAddressButton: UIButton!
    @IBOutlet private weak var retryButton: UIButton!
    @IBOutlet private weak var sentImageView: UIImageView!
    @IBOutlet private weak var sentLabel: UILabel!

    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
}

private extension SendConfirmationViewController {
    func bindViewModel() {
        let input = SendConfirmationViewModel.Input(
            confirmButtonDidTap: comfirmButton.rx.tap.asDriver(),
            reselectAddressButtonDidTap: reselectAddressButton.rx.tap.asDriver(),
            retryButtonDidTap: retryButton.rx.tap.asDriver()
        )
        
        let output = viewModel.build(input: input)
        
        addressLabel.text = output.transactionContext.address
        fiatAmountLabel.text = String(output.transactionContext.fiatAmount.fiat())
        etherAmountLabel.text = output.transactionContext.etherAmount.ether().string
        fiatFeeLabel.text = String(output.transactionContext.fiatFee.fiat())
        
        output
            .sentTransaction
            .drive(onNext: { [weak self] sent in
                self?.handleSentSomeView(with: true)
                self?.dismissViewController()
            })
            .disposed(by: disposeBag)
        
        output
            .isFetching
            .drive(rx.isHUDAnimating)
            .disposed(by: disposeBag)

        output
            .isFetching
            .map { !$0 }
            .drive(comfirmButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output
            .error
            .drive(onNext: { [weak self] error in
                self?.handleSentSomeView(with: false)
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["localizedDescription": error.localizedDescription])
            })
            .disposed(by: disposeBag)
        
        output
            .popToRootViewController
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popToRootViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func handleSentSomeView(with success: Bool) {
        sentImageView.isHidden = false
        sentImageView.image = success ? #imageLiteral(resourceName: "icon_send_success") : #imageLiteral(resourceName: "icon_send_failed")
        
        sentLabel.isHidden = false
        sentLabel.text = success ? "送金完了" : "送金失敗"
        sentLabel.textColor = success ? UIColor.wei.success : UIColor.wei.failed
        
        retryButton.isHidden = success
        reselectAddressButton.isHidden = success
    }
    
    func dismissViewController() {
        comfirmButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
            self?.dismiss(animated: true)
        })
    }
}
