# O MySQL n�o armazena os dados na mem�ria RAM, mas no disco r�gido. 
# Isso expande bastante o limite do tamanho dos dados que conseguiremos gerenciar, 
# sem, no entanto, precisar de outra "gram�tica" para manipula��o de dados.

install.packages("RMySQL")
library(dplyr)
library(RMySQL)

# O primeiro passo importante para trabalhar com dados em um servidor MySQL � fazer a conex�o 
# com uma base de dados. Vamos supor que temos um banco de dados (que, para o MySQL, significa um 
#                                                                 conjunto de tabelas, e n�o apenas 
#                                                                 uma tabela) chamado "PBF" em 
# um servidor local, ou seja, no pr�prio computador, e que dentro desse banco de dados existe a 
# tabela "transferencias201701". O usu�rio e senha fict�cias s�o, respectivamente, "root" e "pass". 
# Usamos, ent�o, a fun��o src_mysql para criar um objeto de "conex�o", que chamaremos de "bd_mysql".

# Exemplo real
# Comecemos com a conex�o:
  
  conexao <- src_mysql(dbname = "tweater", 
                       host = "courses.csrrinzqubik.us-east-1.rds.amazonaws.com", 
                       port = 3306, 
                       user = "student",
                       password = "datacamp")

#fun��o para postgree
# src_postgres()

#tabelas do meu db

  src_tbls(conexao)
 
# Nessa base de dados h� 3 tabelas com informa��es provenientes de uma rede social: "users", 
# que � uma tabela de usu�rios; "tweats" com informa��es sobre postagens de usu�rios; e 
# "comments", com coment�rios �s postagens por outros usu�rios.
# 
# Se voc� sabe algo de SQL, pode usar a fun��o tbl permite fazer queries em linguagem SQL. 
#Por exemplo.
  
  tbl(conexao, sql("SELECT * FROM comments WHERE user_id > 4"))

#N�o d� pra atribuir o resultado da query a um objeto, porque o comando tbl meio que 
  #fica chamando a query, n�o puxa pra minha mem�ria RAM
  
  x <- tbl(conexao, sql("SELECT * FROM comments WHERE user_id > 4 "))

# Mas queremos evitar o uso da linguagem SQL. Com tbl, criamos um objeto de 
# tabela que seja manipul�vel com as fun��es do dplyr, sem, no entanto, import�-la. 
# Vamos fazer isso para as tr�s tabelas da base de dados que estamos usando:
    
comments <- tbl(conexao, "comments")
tweats <- tbl(conexao, "tweats")
users <- tbl(conexao, "users")  

#agora da pra usar o dplyr sem treta:

filter(comments, user_id > 4)

# A partir de agora, as fun��es de manipula��o de dados do dplyr s�o aplic�veis aos novos 
# objetos criados para representar as tabelas que est�o no servidor. Por exemplo, vamos 
# renomear a vari�vel "id" em tweats para "tweat_id" e fazer um left join entre comments e 
# tweats por "tweat_id":
  
tweats2 <- rename(tweats, tweat_id = id)
tabela_join <- left_join(tweats2, comments, "tweat_id")
head(tabela_join)

#eu consigo consultar como head mas n�o consigo dar um View.

# Note que "tweats2" � uma tabela gerada no servidor de SQL e n�o est� na mem�ria RAM de nosso 
# computador.
#Novamente, podemos traduzir a query de R para SQL:
  
show_query(tabela_join)

#que maravilindo

# Uma maneira simples de trazer � mem�ria de seu computador a tabela gerada a partir da query, 
# com as.data.frame importamos a tabela como data frame:
  
tabela <- as.data.frame(tweats)

#agora sim eu consigo dar um View.

###Tabelas tempor�rias versus cria��o de tabelas no MySQL

# Quando utilizamos os verbos do dplyr para manipula��o de dados em servidor MySQL, 
# todas as consultas s�o geradas como tabelas tempor�rias no servidor. Como fazer com que 
# as consultas se tornem tabelas permanentes no servidor?
  
# Vamos trabalhar com um servidor fict�cio, pois n�o temos permiss�o para gerar tabelas 
# no servidor que utilizamos como exemplo no tutorial. Vamos supor que temos uma tabela 
# "pagamentos201701" na nossa base de dados "PBF" e que tal tabela cont�m uma vari�vel 
# "UF" para unidades da federa��o:

conexao <- src_mysql(dbname = "PBF", 
                     user = "root",
                     password = "pass")
tabela <- tbl(conexao, "pagamentos201701")
minha_query <- tabela %>% filter(UF == "ES")

# Ao produzir o comando acima, na pr�tica, nada aconteceu. A execu��o da query s� ocorrer� 
# quando tentarmos trazer a tabela para a mem�ria ("fetch") ou explicitarmos que ela deve ser 
# computada.

# Se quisermos trazer os dados para a mem�ria, utilizamos a fun��o collect.

pagamentos_es <- collect(minha_query)

# Ao usar o comando collect, a query � executada no servidor e os dados enviados ao R.
# O caminho inverso -- subir ao servidor uma tabela -- � feito com a fun��o copy_to

copy_to(dest = conexao, df = pagamentos_es, name = "pagamentos201701_es")

#No entanto, copy_to n�o geram uma nova tabela no servidor. Para que uma nova tabela seja 
# gerada, � preciso definir o argumento "temporary" como "FALSE" (o padr�o � "TRUE"):
  
copy_to(dest = conexao, df = pagamentos_es, name = "pagamentos201701_es", temporary = FALSE)

# Para executar a query no servidor sem que precisemos trazer a tabela e reenvi�-la devemos 
# usar a fun��o compute, que tamb�m tem o argumento "temporary".

compute(minha_query, name = "pagamentos201701_es", temporary = FALSE)

# Sem definir "temporary" como "FALSE", a query ser� executada e a tabela gerada ser� 
# tempor�ria, apenas.
