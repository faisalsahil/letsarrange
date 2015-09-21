module MessageBrandingState
  SYSTEMIZED = 0  # (default) messages generated automatically by the system
  HUMANIZED  = 1  # wording looks user-friendly (humanized) for messages sent by request's requester

  HUMANIZED_WORDING = {
    'offered' => 'How about',
    'countered' => 'How about',
    'accepted' => 'Accepted!',
    'closed' => 'Closed!'
  }
end