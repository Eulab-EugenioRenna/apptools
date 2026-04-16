import { z } from "zod"

export const toolAiSummarySchema = z.object({
  apiAvailable: z.boolean(),
  category: z.string().trim().min(1),
  concepts: z.array(z.string().trim()).default([]),
  derivedLink: z.string().trim(),
  name: z.string().trim().min(1),
  normalizedName: z.string().trim().min(1),
  summary: z.string().trim().min(1),
  tags: z.array(z.string().trim()).default([]),
  useCases: z.array(z.string().trim()).default([])
}).strict()

export const toolAiCreateInputSchema = z.object({
  brand: z.string().trim(),
  category: z.string().trim().min(1),
  link: z.string().trim(),
  name: z.string().trim().min(1),
  source: z.string().trim().min(1),
  summary: toolAiSummarySchema
}).strict()

export const toolAiRecordSchema = z.object({
  brand: z.string().trim(),
  category: z.string().trim().min(1),
  collectionId: z.string().trim().min(1),
  collectionName: z.literal("tools_ai"),
  created: z.string().trim().min(1),
  deleted: z.boolean(),
  id: z.string().trim().min(1),
  link: z.string().trim(),
  name: z.string().trim().min(1),
  source: z.string().trim().min(1),
  summary: toolAiSummarySchema,
  updated: z.string().trim().min(1)
}).strict()

export type ToolAiSummaryInput = z.infer<typeof toolAiSummarySchema>
export type ToolAiCreateInputInput = z.infer<typeof toolAiCreateInputSchema>
export type ToolAiRecordInput = z.infer<typeof toolAiRecordSchema>
