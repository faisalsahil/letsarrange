module RequestState
  OFFERED = 0
  AGREED = 1
  CLOSED = 2
  DELETED = 3

  TRANSITIONS = {
      OFFERED => [AGREED, CLOSED, DELETED],
      AGREED => [OFFERED, CLOSED, DELETED],
      CLOSED => [OFFERED, DELETED],
      DELETED => [],
  }

  HUMANIZED = {
      OFFERED => 'offered',
      AGREED => 'agreed',
      CLOSED => 'closed'
  }
end