DROP INDEX "transactions_recurrence_date";--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "occurrence_month" date;--> statement-breakpoint
CREATE UNIQUE INDEX "transactions_recurrence_month" ON "transactions" USING btree ("recurrence_id","occurrence_month") WHERE "transactions"."recurrence_id" is not null;