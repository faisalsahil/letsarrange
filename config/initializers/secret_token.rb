# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
LetsArrange::Application.config.secret_key_base = ENV['SECRET_TOKEN'] || 'd29cb672b285806e53c68a922254105623fb492fab63eea000372623b89e84d07fbc0b6b496c8786eb412e51bfef4ef087139b7364e24f1dc7d737302460bd0f'