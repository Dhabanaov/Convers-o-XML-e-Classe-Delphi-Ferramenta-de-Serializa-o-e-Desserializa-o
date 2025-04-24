
#Autor - Dhabanna
# Conversão-XML-Serializa e Desserializa


# Conversão de XML para Classe Delphi e Classe para XML

Este projeto foi desenvolvido para facilitar a conversão entre objetos de classe Delphi e arquivos XML. Ele permite que você converta automaticamente arquivos XML em objetos Delphi e, da mesma forma, converta objetos Delphi em arquivos XML. O sistema utiliza a biblioteca XML do Delphi para realizar a serialização e desserialização de dados de forma eficiente e simplificada.

## Funcionalidades

- **Conversão de Classe para XML**: Permite a conversão de objetos de classe Delphi para um arquivo XML. Cada propriedade da classe se torna um nó no XML, mantendo a estrutura de dados clara e legível.
  
- **Conversão de XML para Classe**: Facilita a leitura de arquivos XML e a conversão de seus dados para objetos Delphi correspondentes, preenchendo automaticamente as propriedades das classes.

- **Suporte a Tipos de Dados Comuns**: O sistema lida com tipos de dados básicos como `String`, `Integer`, `Boolean`, e outros, garantindo que a conversão entre XML e classe seja precisa.

- **Facilidade de Integração**: O código foi desenvolvido de maneira modular e pode ser facilmente adaptado para qualquer tipo de classe Delphi e estrutura de XML, tornando-o reutilizável e flexível.

## Como Funciona

1. **Conversão de Classe para XML**: O sistema pega uma instância de uma classe Delphi, cria um documento XML e preenche os nós do XML com os dados da classe. O XML gerado pode ser salvo em um arquivo ou transmitido de outra forma.

2. **Conversão de XML para Classe**: O sistema carrega um arquivo XML, interpreta sua estrutura e preenche uma instância de classe Delphi com os dados correspondentes aos nós XML.

## Exemplo de Uso

### Conversão de Classe para XML

```delphi
type
  TPerson = class
  private
    FName: string;
    FAge: Integer;
  public
    property Name: string read FName write FName;
    property Age: Integer read FAge write FAge;
  end;
