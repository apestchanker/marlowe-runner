module Component.Footer where

import React.Basic (JSX)
import React.Basic.DOM as DOM

newtype Fixed = Fixed Boolean

footer :: JSX
footer = do
  DOM.footer
    { className: "bg-light border-top"
    , children:
        [ DOM.div
            { className: "container"
            , children:
                [ DOM.span
                    { className: "text-muted d-flex justify-content-around"
                    , children:
                        [ DOM.a
                            { className: "btn btn-link text-muted text-primary-hover text-decoration-none"
                            , href: "https://static.iohk.io/terms/iohktermsandconditions.pdf"
                            , target: "_blank"
                            , children:
                                [ DOM.i { className: "h5 bi-file-earmark-text" }
                                , DOM.text "  Terms and Conditions"
                                ]
                            }
                        , DOM.a
                            { className: "btn btn-link text-muted text-primary-hover text-decoration-none"
                            , href: "https://docs.marlowe.iohk.io"
                            , target: "_blank"
                            , children:
                                [ DOM.i { className: "h5 bi-book" }
                                , DOM.text "  Marlowe Documentation"
                                ]
                            }
                        , DOM.a
                            { className: "btn btn-link text-muted text-primary-hover text-decoration-none"
                            , href: "https://play.marlowe.iohk.io"
                            , target: "_blank"
                            , children:
                                [ DOM.i { className: "h5 bi-play-circle" }
                                , DOM.text "  Marlowe Playground"
                                ]
                            }
                        , DOM.a
                            { className: "btn btn-link text-muted text-primary-hover text-decoration-none"
                            , href: "http://marlowescan.com"
                            , target: "_blank"
                            , children:
                                [ DOM.i { className: "h5 bi-globe2" }
                                , DOM.text "  Marlowe Scan"
                                ]
                            }
                        ]
                    }
                ]
            }
        ]
    }
