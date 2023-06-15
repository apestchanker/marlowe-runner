module Component.Widgets where

import Prelude

import ConvertableOptions (defaults, class Defaults)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect (Effect)
import React.Basic (JSX)
import React.Basic.DOM as DOOM
import React.Basic.DOM.Events (preventDefault)
import React.Basic.DOM.Simplified.Generated as DOM
import React.Basic.Events (handler)
import ReactBootstrap (overlayTrigger, tooltip)
import ReactBootstrap.Types as OverlayTrigger
import ReactBootstrap.Icons (Icon)
import ReactBootstrap.Icons as Icons

spinner :: Maybe JSX -> JSX
spinner possibleBody = DOM.div
  { className: "spinner-border"
  , role: "status"
  }
  [ DOM.span { className: "visually-hidden" }
      [ fromMaybe (DOOM.text "Loading...") possibleBody ]
  ]

type LinkOptionalPropsRow =
  ( extraClassNames :: String
  , disabled :: Boolean
  , showBorders :: Boolean
  , tooltipText :: Maybe String
  )

defaultLinkOptionalProps :: { | LinkOptionalPropsRow }
defaultLinkOptionalProps =
  { extraClassNames: ""
  , disabled: false
  , showBorders: false
  , tooltipText: Nothing
  }

type LinkProps =
  ( label :: JSX
  , onClick :: Effect Unit
  | LinkWithIconOptionalProps
  )

link
  :: forall provided
   . Defaults { | LinkOptionalPropsRow } { | provided } { | LinkProps }
  => { | provided }
  -> JSX
link provided = do
  let
    { label, extraClassNames, onClick, disabled, showBorders } =
      defaults defaultLinkOptionalProps provided
    borderClasses =
      if showBorders then " border border-1 bg-light-hover"
      else " text-decoration-underline-hover"
    extraClassNames' = " " <> extraClassNames <> borderClasses <>
      if disabled then " disabled"
      else ""
  DOM.button
    { className: "btn btn-link text-decoration-none text-reset" <> extraClassNames'
    , onClick: handler preventDefault (const $ onClick)
    , type: "button"
    }
    [ label ]

type LinkWithIconOptionalProps = LinkOptionalPropsRow

type LinkWithIconProps =
  ( icon :: Icon
  , label :: JSX
  , onClick :: Effect Unit
  | LinkWithIconOptionalProps
  )

-- FIXME: We should just call `link` here and not repeat the code
linkWithIcon
  :: forall provided
   . Defaults { | LinkWithIconOptionalProps } { | provided } { | LinkWithIconProps }
  => { | provided }
  -> JSX
linkWithIcon provided = do
  let
    { icon, label, extraClassNames, onClick, disabled, showBorders, tooltipText } =
      defaults defaultLinkOptionalProps provided
    borderClasses =
      if showBorders then " border border-1 bg-light-hover"
      else " text-decoration-underline-hover"
    extraClassNames' = " " <> extraClassNames <> borderClasses <>
      if disabled then " disabled"
      else ""
    button = DOM.button
      { className: "btn btn-link " <> extraClassNames'
      , onClick: handler preventDefault (const $ onClick)
      , type: "button"
      }
      [ Icons.toJSX icon
      , DOOM.text " "
      , label
      ]
  case tooltipText of
    Just text -> do
      let
        tooltipJSX = tooltip {} (DOOM.text text)
      DOM.div
        { className: "d-inline-block" }
        [ overlayTrigger
            { overlay: tooltipJSX
            , placement: OverlayTrigger.placement.right
            }
            button
        ]
    Nothing -> button

buttonWithIcon
  :: forall provided
   . Defaults { | LinkWithIconOptionalProps } { | provided } { | LinkWithIconProps }
  => { | provided }
  -> JSX
buttonWithIcon provided = do
  let
    { icon, label, extraClassNames, onClick, disabled } =
      defaults defaultLinkOptionalProps provided
    extraClassNames' = " " <> extraClassNames <>
      if disabled then " disabled"
      else ""
  DOM.button
    { className: "btn btn-primary" <> extraClassNames'
    , onClick: handler preventDefault (const $ onClick)
    , type: "button"
    }
    [ Icons.toJSX icon
    , DOOM.text " "
    , label
    ]

