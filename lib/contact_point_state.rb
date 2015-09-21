module ContactPointState
  UNVERIFIED = 0
  VERIFIED = 1
  DISABLED = 2
  DELETED = 3
  TRUSTED = 4

  TRANSITIONS = {
      UNVERIFIED => [TRUSTED, VERIFIED, DELETED],
      VERIFIED => [DISABLED, DELETED],
      DISABLED => [VERIFIED, DELETED],
      DELETED => [],
      TRUSTED => [VERIFIED, DELETED]
  }

  HUMANIZED = {
      UNVERIFIED => 'unverified',
      VERIFIED => 'verified',
      DISABLED => 'disabled',
      TRUSTED => 'trusted',
  }
end