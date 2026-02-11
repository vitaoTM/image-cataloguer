# app.rb
require 'sinatra'
require 'pathname'
require 'fileutils'
require 'json'

# Ativa as sessões para armazenar o estado do aplicativo
enable :sessions

# Define um segredo de sessão para prevenir erros de HMAC.
set :session_secret, ENV['SESSION_SECRET'] || 'uma_string_secreta_muito_longa_e_aleatoria_para_assinatura_de_sessoes'

# Configurações do Sinatra
set :bind, '0.0.0.0'
set :port, 4567

# Helper method to get all images from a root path
def get_image_list(root_path)
  return [] unless root_path && Pathname.new(root_path).directory?
  Dir.glob(Pathname.new(root_path).join('*.{jpg,jpeg,png,gif}'))
      .sort # Sort by name for consistency
end

# Rota principal - exibe a próxima imagem a ser classificada ou o formulário de pasta
get '/' do
  if params[:path].nil? || params[:path].empty?
    session.clear # Clear the entire session on a new start
    return erb :select_folder
  end

  # Initialize session if it's new
  if session[:images_root] != params[:path]
    session[:images_root] = params[:path].to_s
    session[:current_image_index] = 0
    session[:history] = []
    session[:recent_tags] = []
  end

  all_images = get_image_list(session[:images_root])

  # Ensure index is within bounds
  if session[:current_image_index] >= all_images.size
    session[:current_image_index] = all_images.size - 1
    session[:current_image_index] = 0 if session[:current_image_index] < 0
  end

  current_image_path = all_images[session[:current_image_index]]
  remaining_count = all_images.size - session[:current_image_index]

  erb :index, locals: {
    image_path: current_image_path,
    remaining: remaining_count,
    history_available: session[:history].any?,
    recent_tags: session[:recent_tags]
  }
end

# Nova rota para servir as imagens dinamicamente
get '/image_file' do
  path = params[:path]
  # Verifica se o caminho do arquivo é seguro e existe
  if path && Pathname.new(path).exist?
    send_file path
  else
    status 404
    'Arquivo não encontrado.'
  end
end

# Rota para classificar e mover uma imagem
post '/classify' do
  redirect to('/') unless session[:images_root]

  image_path = params[:image_path]
  tag = params[:tag].strip.downcase

  if image_path && tag && !tag.empty?
    source_path = Pathname.new(image_path)
    dest_dir = Pathname.new(session[:images_root]).join(tag)
    dest_path = dest_dir.join(source_path.basename)

    dest_dir.mkpath unless dest_dir.exist?
    FileUtils.mv(source_path.to_s, dest_path.to_s)

    session[:history] << { source: image_path, destination: dest_path.to_s, action: :classify }
    session[:history] = session[:history].last(10) # Limit history size

    session[:recent_tags].unshift(tag)
    session[:recent_tags].uniq!
    session[:recent_tags] = session[:recent_tags].take(6)
    
    # NOTE: No change to current_image_index is needed.
    # The image at the current index was moved, so the list will shrink,
    # and the next image will naturally be at the same index.
  end

  redirect to("/?path=#{session[:images_root]}")
end


# Rota para desfazer a última ação
post '/undo' do
  redirect to('/') unless session[:images_root]

  if session[:history] && session[:history].any?
    last_action = session[:history].pop
    source_path = Pathname.new(last_action[:destination])
    dest_path = Pathname.new(last_action[:source])

    if source_path.exist?
      # Move o arquivo de volta para a pasta de origem
      FileUtils.mv(source_path.to_s, dest_path.to_s)
    end
    # NOTE: No change to current_image_index is needed.
    # When the page reloads, the restored image will appear at the current index.
  end

  redirect to("/?path=#{session[:images_root]}")
end

# Rota para pular a imagem atual
post '/skip' do
  redirect to('/') unless session[:images_root]
  
  all_images = get_image_list(session[:images_root])
  # Only increment if not at the end of the list
  if session[:current_image_index] < all_images.size - 1
    session[:current_image_index] += 1
  end

  redirect to("/?path=#{session[:images_root]}")
end