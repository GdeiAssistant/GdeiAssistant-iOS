import SwiftUI

struct MessageNavigationDestinationView: View {
    @EnvironmentObject private var container: AppContainer

    let item: AppNotificationItem

    var body: some View {
        if let destination = item.destination {
            destinationView(for: destination)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func destinationView(for destination: MessageNavigationTarget) -> some View {
        switch destination {
        case .announcement:
            AnnouncementDetailView(
                navigationTitleText: localizedString("messages.systemNoticeSection"),
                announcementID: item.targetID ?? item.id,
                fallbackTitle: item.title,
                fallbackContent: item.message,
                fallbackCreatedAt: item.createdAt
            )
        case .news:
            NewsView(viewModel: container.makeNewsViewModel())
        case .marketplace:
            if let targetID = item.targetID {
                MarketplaceDetailView(viewModel: container.makeMarketplaceViewModel(), itemID: targetID)
            } else {
                MarketplaceView(viewModel: container.makeMarketplaceViewModel())
            }
        case .lostFound:
            if let targetID = item.targetID {
                LostFoundDetailView(viewModel: container.makeLostFoundViewModel(), itemID: targetID)
            } else {
                LostFoundView(viewModel: container.makeLostFoundViewModel())
            }
        case .delivery:
            if let targetID = item.targetID {
                DeliveryDetailView(
                    viewModel: container.makeDeliveryViewModel(),
                    orderID: targetID,
                    dismissAfterMutation: false,
                    notificationTargetType: item.targetType,
                    notificationTargetSubID: item.targetSubID,
                    notificationID: item.id
                )
            } else {
                DeliveryView(viewModel: container.makeDeliveryViewModel())
            }
        case .secret:
            if let targetID = item.targetID {
                SecretDetailView(
                    viewModel: container.makeSecretViewModel(),
                    postID: targetID,
                    notificationTargetType: item.targetType,
                    notificationTargetSubID: item.targetSubID,
                    notificationID: item.id
                )
            } else {
                SecretView(viewModel: container.makeSecretViewModel())
            }
        case .express:
            if let targetID = item.targetID {
                ExpressDetailView(
                    viewModel: container.makeExpressViewModel(),
                    postID: targetID,
                    notificationTargetType: item.targetType,
                    notificationTargetSubID: item.targetSubID,
                    notificationID: item.id
                )
            } else {
                ExpressView(viewModel: container.makeExpressViewModel())
            }
        case .topic:
            if let targetID = item.targetID {
                TopicDetailView(
                    viewModel: container.makeTopicViewModel(),
                    postID: targetID,
                    notificationTargetType: item.targetType,
                    notificationTargetSubID: item.targetSubID,
                    notificationID: item.id
                )
            } else {
                TopicView(viewModel: container.makeTopicViewModel())
            }
        case .photograph:
            if let targetID = item.targetID {
                PhotographDetailView(
                    viewModel: container.makePhotographViewModel(),
                    postID: targetID,
                    notificationTargetType: item.targetType,
                    notificationTargetSubID: item.targetSubID,
                    notificationID: item.id
                )
            } else {
                PhotographView(viewModel: container.makePhotographViewModel())
            }
        case .datingCenter:
            DatingCenterView(
                viewModel: container.makeDatingCenterViewModel(
                    initialTab: item.datingCenterTab
                )
            )
        }
    }
}
