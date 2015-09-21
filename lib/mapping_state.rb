module MappingState
  ACTIVE = 0
  CLOSED = 1

  TRANSITIONS = {
      ACTIVE => [CLOSED],
      CLOSED => [],
  }

  HUMANIZED = {
      ACTIVE => 'active',
      CLOSED => 'closed'
  }
end