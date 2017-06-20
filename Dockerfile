FROM ruby:latest
MAINTAINER Kieran Wardle
VOLUME /tmp
EXPOSE 9292
RUN git clone https://github.com/ONSdigital/response-management-ui.git
RUN gem install rack
RUN apt-get install wget
RUN gem install sinatra
RUN bundle install --gemfile=response-management-ui/Gemfile
ENTRYPOINT [ "sh", "-c", "cd response-management-ui && bundle exec rackup -p 9292 -o 0.0.0.0" ]
