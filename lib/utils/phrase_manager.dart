import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class PhraseManager {
  static const String _keyOrder = 'phrase_order';
  static const String _keyIndex = 'phrase_current_index';
  static const String _keyCycle = 'phrase_cycle_number';

  static const List<String> phrases = [
    'O sucesso é a soma de pequenos esforços repetidos dia após dia.',
    'Acredite no seu potencial e vá além dos seus limites.',
    'Cada novo dia é uma oportunidade para recomeçar.',
    'Sua dedicação é a chave para conquistar seus sonhos.',
    'Não espere por oportunidades, crie as suas.',
    'A disciplina supera o talento quando o talento não se dedica.',
    'Grandes realizações começam com decisões corajosas.',
    'O progresso, por menor que seja, sempre conta.',
    'Você é capaz de coisas extraordinárias.',
    'Transforme cada obstáculo em uma escada para crescer.',
    'Consistência é mais importante que intensidade.',
    'O futuro pertence àqueles que se preparam hoje.',
    'Faça hoje o que outros não fazem, viva amanhã como outros não conseguem.',
    'Sua energia define o que você atrai para sua vida.',
    'A melhor forma de prever o futuro é criá-lo.',
    'Cada passo, por menor que seja, te aproxima do seu objetivo.',
    'Não desista, grandes coisas levam tempo.',
    'O segredo do progresso é começar.',
    'Você não precisa ser perfeita, só precisa ser constante.',
    'O trabalho duro supera o talento quando o talento não trabalha duro.',
    'Acredite: o melhor ainda está por vir.',
    'Seja paciente consigo mesma. As grandes conquistas levam tempo.',
    'Hoje é um bom dia para começar algo novo.',
    'Você já superou muitas dificuldades. Continue assim.',
    'O sucesso começa fora da zona de conforto.',
    'Não compare sua jornada com a de ninguém.',
    'A persistência é o caminho do êxito.',
    'Cada dia traz uma nova chance de fazer melhor.',
    'O que você faz todos os dias define quem você se torna.',
    'Invista em você mesma. É o melhor investimento.',
    'Sua história está sendo escrita agora. Faça dela algo grandioso.',
    'Não tenha medo de errar. Tenha medo de não tentar.',
    'A motivação te faz começar. O hábito te faz continuar.',
    'Seja grata pelo que tem e trabalhe pelo que deseja.',
    'O crescimento pessoal é o início de todas as conquistas.',
    'Acredite no processo. Resultados virão.',
    'Você é mais forte do que imagina.',
    'Não espere motivação. Comece e a motivação vai aparecer.',
    'Onde há vontade, há caminho.',
    'Celebre cada vitória, mesmo as pequenas.',
    'Seu trabalho faz a diferença na vida das pessoas.',
    'O sucesso não é acaso, é escolha e esforço.',
    'Permita-se crescer. Você merece.',
    'A cada desafio, você se torna mais forte.',
    'O melhor investimento é na sua própria evolução.',
    'Comece onde você está. Use o que você tem. Faça o que puder.',
    'Sua determinação move montanhas.',
    'Não pare quando estiver cansada. Pare quando estiver pronta.',
    'A jornada de mil quilômetros começa com um único passo.',
    'Você tem tudo que precisa para alcançar seus objetivos.',
    'Agradeça por cada lição que a vida te ensina.',
    'O seu melhor está sempre ao seu alcance.',
    'Foque no progresso, não na perfeição.',
    'Cada dia é uma nova página em branco. Escreva uma história bonita.',
    'A resiliência é o seu superpoder.',
    'Não espere pelas circunstâncias certas. Crie-as.',
    'Você está construindo algo incrível, um passo de cada vez.',
    'O esforço de hoje é o sucesso de amanhã.',
    'Nunca é tarde para ser quem você quer ser.',
    'Acredite no seu sonho, mesmo quando ninguém mais acreditar.',
    'Cada dia é uma nova chance de ser melhor.',
    'Você faz a diferença no mundo, mesmo sem perceber.',
    'O segredo é nunca parar de aprender.',
    'Transforme o impossível em possível, todos os dias.',
    'Sua dedicação não passa despercebida.',
    'Não importa o ritmo, importa não parar.',
    'O sucesso é fazer o que os outros não fazem.',
    'Confie no tempo. Tudo se ajeita.',
    'Você é a arquiteta da sua própria vida.',
    'A coragem de começar já é metade da vitória.',
    'Respire fundo e lembre-se do quanto já conquistou.',
    'A jornada é tão importante quanto o destino.',
    'Pequenas atitudes todos os dias levam a grandes resultados.',
    'Você não está atrasada. Você está exatamente onde precisa estar.',
    'Obrigada por fazer a diferença na vida das pessoas.',
    'Acredite: coisas incríveis estão a caminho.',
    'Cada dia é um presente. Aproveite cada momento.',
    'Sua paixão é o combustível do seu sucesso.',
    'Não diminua seus sonhos. Aumente suas ações.',
    'O valor do seu trabalho vai além do que você imagina.',
    'Você tem o poder de transformar vidas.',
    'Agradeça por tudo e trabalhe por mais.',
    'Não espere reconhecimento. Reconheça seu próprio valor.',
    'Seu comprometimento inspira quem está ao seu redor.',
    'O futuro agradece cada esforço que você faz hoje.',
    'Você faz do mundo um lugar melhor.',
    'Nunca subestime o poder da sua gentileza.',
    'A simplicidade é a ultimate sofisticação.',
    'O êxito nasce quando a preparação encontra a oportunidade.',
    'Cada amanhecer traz novas possibilidades.',
    'A sua dedicação é a sua assinatura.',
    'Permita-se brilhar. O mundo precisa da sua luz.',
    'Não apresse o processo. Confie no timing.',
    'A bravura não é a ausência de medo, é agir apesar dele.',
    'Você é a prova de que tudo é possível.',
    'Ofeito com amor sempre faz a diferença.',
    'Acredite no seu valor e o mundo vai acreditar também.',
    'Você faz mais pela vida das pessoas do que imagina.',
    'Cada conselho seu pode mudar uma vida.',
    'Sua empatia é um dom raro. Use-a com orgulho.',
  ];

  static Future<String> getCurrentPhrase() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final savedDate = prefs.getString('phrase_date') ?? '';

    if (savedDate == todayKey) {
      final idx = prefs.getInt(_keyIndex) ?? 0;
      return phrases[idx.clamp(0, phrases.length - 1)];
    }

    final storedOrder = prefs.getStringList(_keyOrder);
    final currentCycle = prefs.getInt(_keyCycle) ?? 0;
    final savedIndex = prefs.getInt(_keyIndex) ?? 0;

    List<int> order;
    if (storedOrder == null || storedOrder.length != phrases.length) {
      order = List<int>.generate(phrases.length, (i) => i)..shuffle(Random(currentCycle));
      await prefs.setStringList(_keyOrder, order.map((i) => i.toString()).toList());
    } else {
      order = storedOrder.map(int.parse).toList();
    }

    int nextIndex;
    if (savedDate.isEmpty) {
      nextIndex = 0;
    } else {
      nextIndex = savedIndex + 1;
      if (nextIndex >= phrases.length) {
        final newCycle = currentCycle + 1;
        order = List<int>.generate(phrases.length, (i) => i)..shuffle(Random(newCycle));
        await prefs.setStringList(_keyOrder, order.map((i) => i.toString()).toList());
        await prefs.setInt(_keyCycle, newCycle);
        nextIndex = 0;
      }
    }

    await prefs.setInt(_keyIndex, nextIndex);
    await prefs.setString('phrase_date', todayKey);

    return phrases[order[nextIndex]];
  }
}
