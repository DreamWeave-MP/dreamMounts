return {
  DreamMountDismount = [[
Begin DreamMountDismount
  short doOnce

  if ( doOnce == 0 )

    if ( DreamMountMount.doOnce )
      stopScript DreamMountMount
      set DreamMountMount.doOnce to 0
      pcforce1stperson
      player->loopgroup idle 2
    endif

    set doOnce to 1
    return
  endif

  enableplayerjumping
  enableplayerviewswitch

  if ( DreamMountMount.wasThirdPerson )
    pcforce3rdperson
  endif

  MessageBox "Dismount successful."
  set doOnce to 0
  stopscript DreamMountDismount

End DreamMountDismount
]],
DreamMountMount = [[
Begin DreamMountMount
  short doOnce
  short wasThirdPerson

  if ( doOnce == 0 )
    set wasThirdPerson to ( PCGet3rdPerson )

    if ( player->GetSpellReadied == 0 )
      Messagebox "Engage your mount by\ndrawing your magic!"
      pcforce3rdperson
      player->loopgroup idlespell 100000 1
    endif

    disableplayerjumping
    disableplayerviewswitch
    set doOnce to 1
    return
  endif

  if ( player->GetSpellReadied )
    player->playgroup idle 2
    pcforce1stperson
    set doOnce to 0
    stopscript DreamMountMount
  endif

End DreamMountMount
]],
DreamMountForceThirdPerson = [[
Begin DreamMountForceThirdPerson
  short wasThirdPerson
  set wasThirdPerson to ( PCGet3rdPerson )

  PCForce3rdPerson

  disablePlayerViewSwitch

  stopScript DreamMountForceThirdPerson

End DreamMountForceThirdPerson
]],
DreamMountDisableForceThirdPerson = [[
Begin DreamMountDisableForceThirdPerson

  if ( DreamMountForceThirdPerson.wasThirdPerson )
    pcforce3rdperson
  else
    pcforce1stperson
  endif

  enablePlayerViewSwitch

  stopScript DreamMountDisableForceThirdPerson
End DreamMountDisableForceThirdPerson
]],
}
