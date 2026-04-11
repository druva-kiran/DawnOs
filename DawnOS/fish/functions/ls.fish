function ls --wraps='eza -l --icons --group-directories-first' --description 'alias ls eza -l --icons --group-directories-first'
    eza -l --icons --group-directories-first $argv
end
