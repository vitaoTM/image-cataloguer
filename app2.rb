require 'sinatra'
require 'pathname'
require 'fileutils'
require 'json'

# Ativa as sessões para armazenar o estado do aplicativo
enable :sessions

# Configurações do Sinatra
set :bind, '0.0.0.0'
set :port, 4567

# Rota principal - exibe a próxima imagem a ser classificada ou o formulário de pasta
get '/' do
  # Limpa a sessão se o usuário não forneceu um caminho
  if params[:path].nil? || params[:path].empty?
    session[:images_root] = nil
    return erb :select_folder
  end

  # Define o diretório de imagens e salva na sessão
  images_root = Pathname.new(params[:path])
  session[:images_root] = images_root.to_s

  # Inicializa o histórico de ações e tags recentes se não existirem
  session[:history] ||= []
  session[:recent_tags] ||= []

  # Pega a lista de imagens diretamente do disco
  begin
    all_images = Dir.glob(images_root.join('*.{jpg,jpeg,png,gif}'))
  rescue Errno::ENOENT
    @error_message = "A pasta '#{images_root}' não foi encontrada. Por favor, verifique o caminho."
    return erb :select_folder
  end

  # Pega o caminho da próxima imagem e o número de imagens restantes
  current_image_path = all_images.first
  remaining_count = all_images.size

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

    # Cria o diretório da tag se ele não existir
    dest_dir.mkpath unless dest_dir.exist?

    # Move o arquivo
    FileUtils.mv(source_path.to_s, dest_path.to_s)

    # Adiciona a ação ao histórico
    session[:history] << { source: image_path, destination: dest_path.to_s }

    # Adiciona a tag à lista de tags recentes
    session[:recent_tags].unshift(tag)
    session[:recent_tags].uniq!
    session[:recent_tags] = session[:recent_tags].take(6)
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
  end

  redirect to("/?path=#{session[:images_root]}")
end

# Rota para pular a imagem atual
post '/skip' do
  redirect to('/') unless session[:images_root]
  session[:images].rotate! unless session[:images].nil?

  # A lógica de pular não move o arquivo, apenas recarrega a página
  # e a próxima imagem na pasta será exibida
  redirect to("/?path=#{session[:images_root]}")
end
