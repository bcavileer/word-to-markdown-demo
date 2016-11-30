require 'word-to-markdown'
require 'sinatra'
require 'html/pipeline'
require 'rack/coffee'
require 'tempfile'
require 'rack/cors'

module WordToMarkdownServer
  class App < Sinatra::Base

    helpers do
      def html_escape(text)
        Rack::Utils.escape_html(text)
      end
    end

    use Rack::Coffee, root: 'public', urls: '/assets/javascripts'

    use Rack::Cors do
      allow do
        origins '*'
        resource '/raw', :headers => :any, :methods => :post
      end
    end

    get "/" do
      render_template :index, { :error => nil }
    end

    post "/" do
      unless params['doc'][:filename].match /docx?$/i
        error = "It looks like you tried to upload something other than a Word Document."
        render_template :index, { :error => error }
      end
      md = CGI.escapeHTML(WordToMarkdown.new(params['doc'][:tempfile]).to_s)
      html = HTML::Pipeline::MarkdownFilter.new(md).call
      render_template :display, { :md => md, :html => html, :filename => params['doc'][:filename].sub(/\.docx?$/,"") }
    end

    post "/raw" do
      WordToMarkdown.new(params['doc'][:tempfile]).to_s
    end

    def render_template(template, locals={})
      halt erb template, :layout => :layout, :locals => locals
    end

  end
end
