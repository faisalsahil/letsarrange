module OrganizationUserState
  TRUSTED = 0
  UNTRUSTED = 1

  TRANSITIONS = {
      TRUSTED => [],
      UNTRUSTED => [TRUSTED],
  }

  HUMANIZED = {
      TRUSTED => 'trusted',
      UNTRUSTED => 'untrusted'
  }
end