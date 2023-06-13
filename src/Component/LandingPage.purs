module Component.LandingPage where

import Prelude

import Component.ConnectWallet (mkConnectWallet)
import Component.Types (ContractInfo, MkComponentMBase)
import Contrib.React.Svg (SvgUrl(..), svgImg)
import Data.Map (Map)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Marlowe.Runtime.Web.Types as Runtime
import React.Basic (JSX, fragment)
import React.Basic.DOM (text) as DOOM
import React.Basic.DOM.Simplified.Generated as DOM
import React.Basic.Events (handler_)
import React.Basic.Hooks (component)
import WalletContext (WalletContext)

data DisplayOption = Default | About

derive instance Eq DisplayOption

type ContractInfoMap = Map Runtime.ContractId ContractInfo

-- On the app level we keep the previous wallet context
-- so we can reuse pieces of contract info from the previous
-- state in a safe manner.
newtype AppContractInfoMap = AppContractInfoMap
  { walletContext :: Maybe WalletContext
  , map :: ContractInfoMap
  }

type Props =
  { routeToApp :: Effect Unit
  }

mkLandingPage :: MkComponentMBase () (Props -> JSX)
mkLandingPage = do
  connectWallet <- mkConnectWallet
  liftEffect $ component "LandingPage" \{ routeToApp } -> React.do
    pure $ DOM.div { className: "mt-6" } $
      [ DOM.div { className: "fixed-top" }
          [ DOM.nav { className: "navbar mb-lg-3 navbar-expand-sm navbar-light bg-light" } $
              DOM.div { className: "container-xl" }
                [ DOM.a { href: "#", className: "navbar-brand" }
                    [ svgImg { src: marloweLogoUrl, height: "30px", className: "me-2" }
                    , DOOM.text "marlowe"
                    ]
                , DOM.div { className: "navbar-collapse justify-content-end text-end" } $
                    [ DOM.ul { className: "navbar-nav gap-2" } ([] :: Array JSX)
                    ]
                ]
          ]
      , DOM.div { className: "container" }
          $ DOM.div { className: "row justify-content-center" }
          $ DOM.div { className: "col-lg-6 col-12" }
              [ DOM.a { href: "#", onClick: handler_ routeToApp } [ DOOM.text "Go to the app" ]
              , connectWallet { currentlyConnected: Nothing, onWalletConnect: const $ pure unit, onDismiss: pure unit, inModal: false }
              ]
      ]

marloweLogoUrl :: SvgUrl
marloweLogoUrl = SvgUrl "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzciIGhlaWdodD0iNDMiIHZpZXdCb3g9IjAgMCAzNyA0MyIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTIxLjU1MzIgMS43NzIyMkwxOC40ODI1IDBMMC4wNjMyMzI0IDEwLjYzNDlWMzEuOTAzMUwwLjc3MDkwNSAzMi4zMTE2TDMuMTMzODcgMzMuNjc1M0wxOC40ODI1IDQyLjUzNzlMMjQuNjIyMyAzOC45OTM1VjM1LjQ0NzVWMTcuNzIzOEwxMi4zNDI3IDEwLjYzNDlMOS4yNzM2MyAxMi40MDcxTDIxLjU1MzIgMTkuNDk2VjM3LjIxOTdMMTguNDgyNSAzOC45OTM1TDMuMTMzODcgMzAuMTMwOFYxMi40MDcxTDE4LjQ4MjUgMy41NDQ0NUwzMy44MzI3IDEyLjQwNzFWMzMuNjc1M0wzNi45MDE4IDMxLjkwMzFWMTAuNjM0OUwyMS41NTMyIDEuNzcyMjJaIiBmaWxsPSIjNTExQ0Y3Ii8+CjxwYXRoIGQ9Ik0xNS40MTM4IDguODYyNTVMMjcuNjkzMyAxNS45NTE0VjM3LjIxOTZMMzAuNzYyNSAzNS40NDc0VjE0LjE3OTJMMTguNDgyOSA3LjA4ODgxTDE1LjQxMzggOC44NjI1NVoiIGZpbGw9IiM1MTFDRjciLz4KPC9zdmc+Cg=="
