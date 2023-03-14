module OptimalRain
  module Views
  end
end

class OptimalRain::Views::Layout < Phlex::HTML
  def template(&)
    doctype
    head_template

    body do
      header do
        h1 { "Cycle runner" }
      end
      main
      yield_content(&)
    end
  end

  def head_template
    head do
      meta charset: "UTF-8"
      meta "http-equiv": "X-UA-Compatible", content: "IE=edge"
      meta name: "viewport", content: "width=device-width", "initial-scale": 1.0
      link rel: "stylesheet", href: "https://cdn.simplecss.org/simple.min.css"
      link rel: "stylesheet", href: "https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css"
      link rel: "stylesheet", href: "2_main.css"
      script src: "https://cdn.jsdelivr.net/npm/flatpickr"
      script src: "main.js"
      title { "Optimal Rain" }
    end
  end
end
