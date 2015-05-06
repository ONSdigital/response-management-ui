module BeyondMock
  module Routes
    class ProductService < Base

      # Create product job.
      post '/productservice/products/jobs/?' do
        request_body = JSON.parse(request.body.read)
        erb :create_product_job, locals: { code: request_body['code'].upcase,
                                           type: request_body['type'].downcase }
      end

      # List products.
      get '/productservice/products/?' do
        erb :products
      end

      # List product jobs.
      get '/productservice/products/jobs/?' do
        erb :product_jobs
      end

      # List single product jobs.
      get '/productservice/products/:code/jobs/?' do |code|
        erb :jobs_for_product, locals: { code: code.upcase }
      end
    end
  end
end
