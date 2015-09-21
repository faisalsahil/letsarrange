module LineItemState
  OFFERED = 0
  COUNTERED = 1
  ACCEPTED = 2
  CLOSED = 3
  DELETED = 4

  TRANSITIONS = {
      OFFERED => [COUNTERED, ACCEPTED, CLOSED, DELETED],
      COUNTERED => [OFFERED, ACCEPTED, CLOSED, DELETED],
      ACCEPTED => [OFFERED, COUNTERED, CLOSED, DELETED],
      CLOSED => [OFFERED, ACCEPTED, DELETED],
      DELETED => [],
  }

  HUMANIZED = {
      OFFERED => 'offered',
      COUNTERED => 'countered',
      ACCEPTED => 'accepted',
      CLOSED => 'closed'
  }
end