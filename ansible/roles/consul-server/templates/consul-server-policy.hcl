node "{{ ansible_hostname }}" {
  policy = "write"
}

key_prefix "{{ ansible_hostname }}/" {
  policy = "write"
}

key_prefix "shared/" {
  policy = "write"
}

node_prefix "" {
  policy = "read"
}
agent_prefix "" {
  policy = "read"
}
agent "{{ ansible_hostname }}" {
  policy = "write"
}
event_prefix "" {
  policy = "read"
}
service_prefix "{{ ansible_hostname }}" {
  policy = "write"
}
