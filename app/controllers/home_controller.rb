class HomeController < ApplicationController
  layout "home"
  allow_unauthenticated_access

  def index
  end

  def roadmap
    redirect_to home_path
  end

  def faq
    @faqs = [
      [
        "What is granite-MD?",
        "A web app for writing and organising Markdown notes, inspired by Obsidian but designed for the browser. Notes live in workspaces, which hold folders and pages."
      ],
      [
        "Is it ready to use?",
        "You can sign up, create workspaces and write pages today, but it is in early development. File uploads, page links and paid plans are not built yet. The roadmap on the About page shows what is where."
      ],
      [
        "Where are my notes stored?",
        "In the app's database, not as files on your device. [HOSTING: where the service runs and how it is backed up]"
      ],
      [
        "Can I export my notes?",
        "Not yet. There is no export feature at the moment."
      ],
      [
        "How much storage do I get?",
        "Every account gets 50 MB, counted across the pages in your workspaces. Each workspace shows how much has been used."
      ],
      [
        "Does it cost anything?",
        "It is free while in development. Plans are planned but not final: Free Plan with 50MB, Education at $2.50 a month with 1 GB, and Paid at $5 a month with 3 GB. Billing is not built yet."
      ],
      [
        "What Markdown is supported?",
        "Headings, bold, italic and strikethrough, links, images, lists, task lists, quotes, code blocks and horizontal rules. A safe subset of HTML also works. Scripts, frames and forms are removed from the preview."
      ],
      [
        "Does it save automatically?",
        'Yes. Edits are saved shortly after you stop typing, and switching to another file saves the one you were on. If a save fails, a "Save failed" message appears under the editor.'
      ],
      [
        "What is a workspace?",
        "A workspace is a collection of folders and pages, like an Obsidian vault. When you create one you pick a use case (personal, education or business) and can place it under an organisation."
      ],
      [
        "How do I reset my password?",
        'Choose "Forgot password?" on the login page and enter your email address. You will be sent a reset link that expires after 15 minutes.'
      ],
      [
        "Can I run it myself?",
        "Yes. granite-MD is published as a Docker image and needs a Postgres and a Redis database plus an SMTP service for email. The project README has a sample docker-compose file. https://github.com/Acidicts/GraniteMD"
      ],
      [
        "How do I report a bug?",
        "Create a github issue at https://github.com/Acidicts/GraniteMD for any non sensitive bugs"
      ]
    ]
  end

  def about
  end

  def team
  end
end
