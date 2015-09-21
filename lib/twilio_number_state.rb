module TwilioNumberState
  ACTIVE = 0
  DELETED = 1

  TRANSITIONS = {
      ACTIVE => [DELETED],
      DELETED => [ACTIVE]
  }

  HUMANIZED = {
      ACTIVE => 'active',
      DELETED => 'deleted'
  }
end