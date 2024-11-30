import OpenAI from 'openai';
import { zodResponseFormat } from 'openai/helpers/zod';
import z from 'zod';

const schema = z.object({
  quizzes: z.array(
    z.object({
      question: z.string(),
      answer: z.string()
    })
  )
});
type QuizProps = z.infer<typeof schema>;

export async function fetchGPT(): Promise<QuizProps> {
  const client = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY
  });

  const chatCompletion = await client.beta.chat.completions.parse({
    messages: [
      {
        role: 'user',
        content: 'なぞなぞの問題と答えを難易度順に3つ作成してください。'
      }
    ],
    model: 'gpt-4o',
    response_format: zodResponseFormat(schema, 'responseSchema')
  });

  return chatCompletion.choices[0].message.parsed as QuizProps;
}

fetchGPT()
  .then((x) => console.log(x))
  .catch(console.error);
