# O MySQL não armazena os dados na memória RAM, mas no disco rígido. 
# Isso expande bastante o limite do tamanho dos dados que conseguiremos gerenciar, 
# sem, no entanto, precisar de outra "gramática" para manipulação de dados.

install.packages("RMySQL")
library(dplyr)
library(RMySQL)

# O primeiro passo importante para trabalhar com dados em um servidor MySQL é fazer a conexão 
# com uma base de dados. Vamos supor que temos um banco de dados (que, para o MySQL, significa um 
#                                                                 conjunto de tabelas, e não apenas 
#                                                                 uma tabela) chamado "PBF" em 
# um servidor local, ou seja, no próprio computador, e que dentro desse banco de dados existe a 
# tabela "transferencias201701". O usuário e senha fictícias são, respectivamente, "root" e "pass". 
# Usamos, então, a função src_mysql para criar um objeto de "conexão", que chamaremos de "bd_mysql".

# Exemplo real
# Comecemos com a conexão:
  
  conexao <- src_mysql(dbname = "tweater", 
                       host = "courses.csrrinzqubik.us-east-1.rds.amazonaws.com", 
                       port = 3306, 
                       user = "student",
                       password = "datacamp")

#função para postgree
# src_postgres()

#tabelas do meu db

  src_tbls(conexao)
 
# Nessa base de dados há 3 tabelas com informações provenientes de uma rede social: "users", 
# que é uma tabela de usuários; "tweats" com informações sobre postagens de usuários; e 
# "comments", com comentários às postagens por outros usuários.
# 
# Se você sabe algo de SQL, pode usar a função tbl permite fazer queries em linguagem SQL. 
#Por exemplo.
  
  tbl(conexao, sql("SELECT * FROM comments WHERE user_id > 4"))

#Não dá pra atribuir o resultado da query a um objeto, porque o comando tbl meio que 
  #fica chamando a query, não puxa pra minha memória RAM
  
  x <- tbl(conexao, sql("SELECT * FROM comments WHERE user_id > 4 "))

# Mas queremos evitar o uso da linguagem SQL. Com tbl, criamos um objeto de 
# tabela que seja manipulável com as funções do dplyr, sem, no entanto, importá-la. 
# Vamos fazer isso para as três tabelas da base de dados que estamos usando:
    
comments <- tbl(conexao, "comments")
tweats <- tbl(conexao, "tweats")
users <- tbl(conexao, "users")  

#agora da pra usar o dplyr sem treta:

filter(comments, user_id > 4)

# A partir de agora, as funções de manipulação de dados do dplyr são aplicáveis aos novos 
# objetos criados para representar as tabelas que estão no servidor. Por exemplo, vamos 
# renomear a variável "id" em tweats para "tweat_id" e fazer um left join entre comments e 
# tweats por "tweat_id":
  
tweats2 <- rename(tweats, tweat_id = id)
tabela_join <- left_join(tweats2, comments, "tweat_id")
head(tabela_join)

#eu consigo consultar como head mas não consigo dar um View.

# Note que "tweats2" é uma tabela gerada no servidor de SQL e não está na memória RAM de nosso 
# computador.
#Novamente, podemos traduzir a query de R para SQL:
  
show_query(tabela_join)

#que maravilindo

# Uma maneira simples de trazer à memória de seu computador a tabela gerada a partir da query, 
# com as.data.frame importamos a tabela como data frame:
  
tabela <- as.data.frame(tweats)

#agora sim eu consigo dar um View.

###Tabelas temporárias versus criação de tabelas no MySQL

# Quando utilizamos os verbos do dplyr para manipulação de dados em servidor MySQL, 
# todas as consultas são geradas como tabelas temporárias no servidor. Como fazer com que 
# as consultas se tornem tabelas permanentes no servidor?
  
# Vamos trabalhar com um servidor fictício, pois não temos permissão para gerar tabelas 
# no servidor que utilizamos como exemplo no tutorial. Vamos supor que temos uma tabela 
# "pagamentos201701" na nossa base de dados "PBF" e que tal tabela contém uma variável 
# "UF" para unidades da federação:

conexao <- src_mysql(dbname = "PBF", 
                     user = "root",
                     password = "pass")
tabela <- tbl(conexao, "pagamentos201701")
minha_query <- tabela %>% filter(UF == "ES")

# Ao produzir o comando acima, na prática, nada aconteceu. A execução da query só ocorrerá 
# quando tentarmos trazer a tabela para a memória ("fetch") ou explicitarmos que ela deve ser 
# computada.

# Se quisermos trazer os dados para a memória, utilizamos a função collect.

pagamentos_es <- collect(minha_query)

# Ao usar o comando collect, a query é executada no servidor e os dados enviados ao R.
# O caminho inverso -- subir ao servidor uma tabela -- é feito com a função copy_to

copy_to(dest = conexao, df = pagamentos_es, name = "pagamentos201701_es")

#No entanto, copy_to não geram uma nova tabela no servidor. Para que uma nova tabela seja 
# gerada, é preciso definir o argumento "temporary" como "FALSE" (o padrão é "TRUE"):
  
copy_to(dest = conexao, df = pagamentos_es, name = "pagamentos201701_es", temporary = FALSE)

# Para executar a query no servidor sem que precisemos trazer a tabela e reenviá-la devemos 
# usar a função compute, que também tem o argumento "temporary".

compute(minha_query, name = "pagamentos201701_es", temporary = FALSE)

# Sem definir "temporary" como "FALSE", a query será executada e a tabela gerada será 
# temporária, apenas.
