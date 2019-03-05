import UIKit

protocol HelloWorld: Mocking {
    func greet(person: String) -> String
    func bye(person: String) -> String
}

protocol NonMockableProtocol {
    func nonMockableGreet(person: String) -> String
}

protocol BuyAnimating: Mocking {
    func animateBuy(view: UIView,
                    detailsView: VinylDetailsView,
                    barView: ShoppingBarView)
}
