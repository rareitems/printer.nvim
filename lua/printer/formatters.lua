local formatters = {
  lua = function(text)
    return string.format("print([[%s: ]] .. %s)", text, text)
    -- for nvim stuff
    -- return string.format('print([[%s: ]] .. vim.inspect(%s))', text, text)
  end,

  python = function(text)
    return string.format('print("%s:", %s)', text, text)
  end,

  javascript = function(text)
    return string.format('console.log("%s:", %s)', text, text)
  end,

  typescript = function(text)
    return string.format('console.log("%s:", %s)', text, text)
  end,

  go = function(text)
    return string.format('fmt.Println("%s:", %s)', text, text)
  end,

  vim = function(text)
    return string.format('echo "%s: ".%s', text, text)
  end,

  rust = function(text)
    return string.format([[println!("{%s:#?}");]], text)
  end,

  zsh = function(text)
    return string.format('echo "%s: $%s"', text, text)
  end,

  bash = function(text)
    return string.format('echo "%s: $%s"', text, text)
  end,

  sh = function(text)
    return string.format('echo "%s: $%s"', text, text)
  end,

  java = function(text)
    return string.format('System.out.println("%s: " + %s);', text, text)
  end,

  cpp = function(text)
    return string.format('std::cout << "%s: " << %s << endl;', text, text)
  end,
}

return formatters
