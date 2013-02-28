# Concept:
# - server runs as root
# - separate config in /etc/ (writeable by root only, no user configs)
# - config holds a list of user that are allowed to access functionality (granular access: on module (package) basis)
# - safe interpreter mode (per user)
# - console bindings to gather information, allow administrative tasks (super user account)
# - maybe use pam, otherwise use hashed passwords to restrict user access
