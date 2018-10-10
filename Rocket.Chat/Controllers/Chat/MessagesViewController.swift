//
//  MessagesViewController.swift
//  Rocket.Chat
//
//  Created by Filipe Alvarenga on 19/09/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import UIKit
import RocketChatViewController
import RealmSwift
import DifferenceKit

protocol SizingCell: class {
    static var sizingCell: UICollectionViewCell & ChatCell { get }
    static func size(for viewModel: AnyChatItem, with horizontalMargins: CGFloat) -> CGSize
}

extension SizingCell {
    static func size(for viewModel: AnyChatItem, with horizontalMargins: CGFloat) -> CGSize {
        var mutableSizingCell = sizingCell
        mutableSizingCell.prepareForReuse()
        mutableSizingCell.adjustedHorizontalInsets = horizontalMargins
        mutableSizingCell.viewModel = viewModel
        mutableSizingCell.configure()
        mutableSizingCell.setNeedsLayout()
        mutableSizingCell.layoutIfNeeded()

        return mutableSizingCell.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

final class MessagesViewController: RocketChatViewController {

    let viewModel = MessagesViewModel(controllerContext: nil)
    let viewSubscriptionModel = MessagesSubscriptionViewModel()
    let viewSizingModel = MessagesSizingManager()
    let composerViewModel = MessagesComposerViewModel()

    var subscription: Subscription! {
        didSet {
            viewModel.subscription = subscription
            viewSubscriptionModel.subscription = subscription
        }
    }

    var sectionsToAddLater: [AnyChatSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        composerView.delegate = self

        collectionView.register(BasicMessageCell.nib, forCellWithReuseIdentifier: BasicMessageCell.identifier)
        collectionView.register(SequentialMessageCell.nib, forCellWithReuseIdentifier: SequentialMessageCell.identifier)
        collectionView.register(DateSeparatorCell.nib, forCellWithReuseIdentifier: DateSeparatorCell.identifier)
        collectionView.register(AudioMessageCell.nib, forCellWithReuseIdentifier: AudioMessageCell.identifier)
        collectionView.register(VideoMessageCell.nib, forCellWithReuseIdentifier: VideoMessageCell.identifier)
        collectionView.register(ReactionsCell.nib, forCellWithReuseIdentifier: ReactionsCell.identifier)
        collectionView.register(FileMessageCell.nib, forCellWithReuseIdentifier: FileMessageCell.identifier)
        collectionView.register(TextAttachmentCell.nib, forCellWithReuseIdentifier: TextAttachmentCell.identifier)
        collectionView.register(ImageMessageCell.nib, forCellWithReuseIdentifier: ImageMessageCell.identifier)
        collectionView.register(QuoteCell.nib, forCellWithReuseIdentifier: QuoteCell.identifier)
        collectionView.register(MessageURLCell.nib, forCellWithReuseIdentifier: MessageURLCell.identifier)

        dataUpdateDelegate = self
        viewModel.controllerContext = self
        viewModel.onDataChanged = {
            self.updateData(with: self.viewModel.dataSorted)
        }

        viewSubscriptionModel.onDataChanged = {
            // TODO: handle updates on the Subscription object, such like title view
        }
    }

    func openURL(url: URL) {
        WebBrowserManager.open(url: url)
    }

}

extension MessagesViewController {

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if viewModel.numberOfSections - indexPath.section < 5 {
            viewModel.fetchMessages(from: viewModel.oldestMessageDateBeingPresented)
        }

        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let item = viewModel.item(for: indexPath) else {
            return .zero
        }

        if let size = viewSizingModel.size(for: item.differenceIdentifier) {
            return size
        } else {
            guard let sizingCell = UINib(nibName: item.relatedReuseIdentifier, bundle: nil).instantiate() as? SizingCell else {
                return .zero
            }

            let horizontalMargins = collectionView.adjustedContentInset.left + collectionView.adjustedContentInset.right
            var size = type(of: sizingCell).size(for: item, with: horizontalMargins)
            size = CGSize(width: UIScreen.main.bounds.width - horizontalMargins, height: size.height)
            viewSizingModel.set(size: size, for: item.differenceIdentifier)

            return size
        }
    }

}

extension MessagesViewController: ChatDataUpdateDelegate {

    func didUpdateChatData(newData: [AnyChatSection]) {
        viewModel.data = newData
    }

}

extension MessagesViewController: UIDocumentInteractionControllerDelegate {

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }

}

extension MessagesViewController: UserActionSheetPresenter {

    func presentActionSheetForUser(_ user: User, source: (view: UIView?, rect: CGRect?)?) {
        presentActionSheetForUser(user, subscription: subscription, source: source)
    }

}
