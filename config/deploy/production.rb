# frozen_string_literal: true

server "app.flyweight.org",
       user:  "deploy",
       roles: %w[app db web]
