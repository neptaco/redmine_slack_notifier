FROM redmine:4.0.4

RUN apt-get update \
    && apt-get install -y \
       vim less \
       build-essential libpq-dev nodejs iproute2 \
    && gem install rubocop ruby-debug-ide debase \
    #&& git clone https://github.com/bizyman/sidebar_hide.git plugins/sidebar_hide \
    #&& git clone https://github.com/cat-in-136/redmine_view_hook_for_dev plugins/redmine_view_hook_for_dev \
    && sed -i 's/rails | rake | passenger )/rails | rdebug-ide | rake | passenger )/' /docker-entrypoint.sh

COPY Gemfile.local .
COPY .env .
