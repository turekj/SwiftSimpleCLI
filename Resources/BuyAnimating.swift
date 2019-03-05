import UIKit

protocol BuyAnimating: Mocking {
    func animateBuy(view: UIView,
                    detailsView: VinylDetailsView,
                    barView: ShoppingBarView,
                    completion: @escaping () -> Void)
}
